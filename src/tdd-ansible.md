# Test-Driven Ansible with Molecule
## Introduction

**This is based on an old post I wrote back in 2017 which has been
updated to be compatible with the latest versions of tools as of
June 2020. I suspect attitudes towards testing within the Ansible
community have changed since I originally wrote this.**

As a Sys Admin type who likes to automate things I've learnt several
configuration management tools over the years.  The first one I learnt
was [Chef](https://www.chef.io), in the Chef ecosystem they advocate
that all cookbooks should have tests.  In the Chef world testing is
encouraged so much they even have canonical tools to help such as
[Kitchen](https://kitchen.ci)[^test-kitchen] and
[InSpec](https://www.inspec.io).  Whenever I was writing Chef I would
use these tools to follow a test-driven development (TDD) just like
I'd heard software developers banging on about when writing apps.  I
immediately fell in love.

I then discovered [Ansible](https://www.ansible.com) which I was
attracted to for its simplicity in comparison to writing Ruby code
with Chef.  I immediately re-wrote all of the Chef stuff we had at
work and persuaded the team to make the switch.  I still love Chef,
just Ansible was a lot quicker to understand which was going to mean
much easier on-boarding of new team members

After writing a lot of Ansible I couldn't help but think something was
missing, it was the TDD workflow I'd fallen in love with when writing
Chef.  The Ansible community don't believe testing playbook is
necessary on the same scale as it is with Chef as the execution of a
playbook is strictly ordered and you are just writing YAML files
rather than a full programming language.  You'd almost be testing
Ansible itself which already has a substantial amount of testing.
Nevertheless I still missed the workflow and having tests gave me the
confidence to refactor things or try new features out when learning.
I missed having a 'clean' environment a command away to try out what
I'd just written.  Furthermore, some of the simplicity of Ansible
starts to get lost once a million values have been abstracted out into
variables or you start introducing logic to accommodate various
operating systems, once this happens testing can't hurt.

I've since discovered
[Molecule](https://molecule.readthedocs.io/en/latest) which allows me
to write Ansible in a similar way to how I used to write Chef.  I
write tests first in
[Testinfra](https://testinfra.readthedocs.io/en/latest) which is the
Python equivalent to the [Serverspec](https://serverspec.org) tests
I'd gotten used to writing for Chef.  I had my workflow back and I
have increased confidence in the Ansible code I write.  In addition to
testing Molecule ensures you follow best practices by running your
code through [Ansible Lint](https://docs.ansible.com/ansible-lint) and
performs an idempotence check.

In this post I hope to show how you can use Molecule to TDD a simple
Ansible role which installs Ruby from source.  I will show how you can
test with Testinfra and also include an example of testing within the
Ansible itself which is often advocated.  The final project can be found
on my [Github](https://github.com/rosstimson/tdd-ansible-ruby-role).


## Initial Setup

Although I'll show all the code step by step it is assumed that you
already have some Ansible knowledge.  You should also have a working
Python 3 environment setup along with [Docker](https://www.docker.com).

I recommend using a virtual environment to store all the necessary
Python dependencies, Python 3 has this functionality baked in[^venv]
but I prefer [Pipenv](https://pipenv.pypa.io/en/latest) so lets
install Pipenv and Molecule itself to setup the project:

    $ pip install --user -U "molecule[lint]" pipenv

    $ molecule init role --verifier-name testinfra ruby

    $ cd ruby

    $ pipenv --python 3

    $ pipenv install --dev "molecule[lint]" testinfra docker

In order to run `molucule` commands within the context of the
virtualenv just prefix everything with `pipenv run` or jump into a
virtualenv shell with `pipenv shell`.

Test everything is setup correctly by running the dummy code that was
created:

    $ pipenv shell

    $ molecule test

You should see a Docker container being created and prepared, followed
by a short Ansible run.  Now the container is in a converged state
Molecule proceeds to run various tests such as an idempotence check,
linting of both Ansible and Python, and lastly Testinfra.

### Troubleshooting Common Issues

If you are unable to successfully run `molecule test` a few common
issues I've encountered are:

* Molecule has also been installed on the system globally.  Depending
  on how your `$PATH` is setup this might mean that when you run the
  `molecule` command it is using that of the system install rather
  than within the virtualenv, this can cause all sorts of weird
  errors.  Make sure that it is the virtualenv install that you are
  using by checking `which molecule`, this should show something like
  `$HOME/.local/share/virtualenvs/ruby-AkMRfn7e/bin/molecule` if
  you're using Pipenv as suggested.

* Don't change the name of the parent directory, in our example this is
  `ruby`, it can cause issues with the virtualenv unless you recreate it.

* Similar to the warning above, don't change the name of the role in
  `playbook.yml`, it must match that of the parent directory.

## Writing Our First Test

Change the operating system that we're dealing with, I work a lot with AWS so opted for Amazon Linux.  Edit `molecule/default/molecule.yml`:

    ---
    dependency:
      name: galaxy
    driver:
      name: docker
    platforms:
      - name: instance
        image: amazonlinux      <<<<<<<<<<<<
    provisioner:
      name: ansible
    verifier:
      name: testinfra

As with any test driven development we should start by writing some
tests before we then make those test pass by writing our Ansible code.
Molecule has already setup an example test file
`molecule/default/tests/test_default.py` that we'll edit.  First we'll
test that Ruby's build dependencies are installed, in reality testing
these is probably overkill but it'll serve as an example.

    def test_gcc_is_installed(host):
        pkg = host.package("gcc")

        assert pkg.is_installed

When running `molecule test` it wraps a bunch of `molecule` sub-commands
that create a container, runs tests, and then destroys that container.
We can speed up the feedback loop when developing by running
the individual `molecule` sub-commands instead.

Create the Docker container and then run our tests with the following
commands, we expect them to fail at this point since we've not run any
Ansible on the container.

    $ molecule create

    $ molecule verify
      --> Test matrix

    └── default
        └── verify

    --> Scenario: 'default'
    --> Action: 'verify'
    --> Executing Testinfra tests found in /home/rosstimson/code/ansible/ruby/molecule/default/tests/...
        ============================= test session starts ==============================
        platform linux -- Python 3.8.2, pytest-5.4.2, py-1.8.1, pluggy-0.13.1
        rootdir: /home/rosstimson/code/ansible/ruby/molecule/default
        plugins: testinfra-5.1.0
    collected 1 item

        tests/test_default.py F                                                  [100%]

        =================================== FAILURES ===================================
        __________________ test_gcc_is_installed[ansible://instance] ___________________

        host = <testinfra.host.Host ansible://instance>

            def test_gcc_is_installed(host):
                pkg = host.package("gcc")

        >       assert pkg.is_installed
        E       assert False
        E        +  where False = <package gcc>.is_installed

        tests/test_default.py:14: AssertionError
        =========================== short test summary info ============================
        FAILED tests/test_default.py::test_gcc_is_installed[ansible://instance] - ass...
        ============================== 1 failed in 3.20s ===============================

## Writing Ansible to Pass Test

This test failure is exactly what we wanted since we've not written
any Ansible to install the `gcc` package, we'll address that now.
Edit `tasks/main.yml`:

    ---

    - name: install ruby build dependencies
      yum:
        name: gcc

Run the Ansible playbook with:

    $ molecule converge
    --> Test matrix

    └── default
        ├── dependency
        ├── create
        ├── prepare
        └── converge

    --> Scenario: 'default'
    --> Action: 'dependency'
    Skipping, missing the requirements file.
    Skipping, missing the requirements file.
    --> Scenario: 'default'
    --> Action: 'create'
    Skipping, instances already created.
    --> Scenario: 'default'
    --> Action: 'prepare'
    Skipping, prepare playbook not configured.
    --> Scenario: 'default'
    --> Action: 'converge'
    --> Sanity checks: 'docker'

        PLAY [Converge] ****************************************************************

        TASK [Gathering Facts] *********************************************************
    [WARNING]: Platform linux on host instance is using the discovered Python
    interpreter at /usr/bin/python, but future installation of another Python
    interpreter could change this. See https://docs.ansible.com/ansible/2.9/referen
    ce_appendices/interpreter_discovery.html for more information.
        ok: [instance]

        TASK [Include ruby] ************************************************************

        TASK [ruby : install ruby build dependencies] **********************************
    [DEPRECATION WARNING]: Invoking "yum" only once while using a loop via
    squash_actions is deprecated. Instead of using a loop to supply multiple items
    and specifying `name: "{{ item }}"`, please use `name: ['gcc']` and remove the
    loop. This feature will be removed in version 2.11. Deprecation warnings can be
     disabled by setting deprecation_warnings=False in ansible.cfg.
        changed: [instance] => (item=['gcc'])

        PLAY RECAP *********************************************************************
        instance                   : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

Verify our test is now passing:

    $ molecule verify
    --> Test matrix

    └── default
        └── verify

    --> Scenario: 'default'
    --> Action: 'verify'
    --> Executing Testinfra tests found in /home/rosstimson/code/ansible/ruby/molecule/default/tests/...
        ============================= test session starts ==============================
        platform linux -- Python 3.8.2, pytest-5.4.2, py-1.8.1, pluggy-0.13.1
        rootdir: /home/rosstimson/code/ansible/ruby/molecule/default
        plugins: testinfra-5.1.0
    collected 1 item

        tests/test_default.py .                                                  [100%]

        ============================== 1 passed in 3.14s ===============================
    Verifier completed successfully.
    code/ansible/ruby took 4s

## Keeping Things DRY

We could write a test like this for each of our dependencies needed to
build Ruby but that would be a lot of repetition.  To DRY[^dry] this
up we can use [Pytest
Parametrizing](https://docs.pytest.org/en/latest/parametrize.html).
Note that in order to use this we have to `import pytest`.  Edit
`molecule/default/tests/test_default.py` to include the rest of the
necessary packages:

    import pytest

    @pytest.mark.parametrize("name", [
        ("automake"),
        ("bison"),
        ("gcc"),
        ("gdbm-devel"),
        ("libffi-devel"),
        ("libyaml-devel"),
        ("ncurses-devel"),
        ("openssl-devel"),
        ("readline-devel"),
        ("tar"),
        ("zlib-devel"),
    ])
    def test_ruby_build_dependencies(host, name):
        pkg = host.package(name)
        assert pkg.is_installed

Go ahead and run `molecule verify` again to make sure the tests fail.
We can then fix them with the following additions to the Ansible in
`tasks/main.yml`:

    ---

    - name: install ruby build dependencies
      yum:
        name:
          - automake
          - bison
          - gcc
          - gdbm-devel
          - libffi-devel
          - libyaml-devel
          - ncurses-devel
          - openssl-devel
          - readline-devel
          - tar
          - zlib-devel

And again we can make sure our tests are now passing by converging and
verifying again.  This 'verify -> converge -> verify' workflow is what I
spoke about in the introduction.

## Further Tests

Now that we've seen how you write basic tests and how the Molecule
'verify -> converge -> verify' workflow works we can flesh out our
test suite by testing the Ruby executable which after all is the
ultimate aim of this Ansible role.  Modify the
`molecule/default/tests/test_default.py` file to include the new
tests, note the `import re` for using regexes:

    import pytest
    import re

    @pytest.mark.parametrize("name", [
        ("automake"),
        ("bison"),
        ("gcc"),
        ("gdbm-devel"),
        ("libffi-devel"),
        ("libyaml-devel"),
        ("ncurses-devel"),
        ("openssl-devel"),
        ("readline-devel"),
        ("tar"),
        ("zlib-devel"),
    ])
    def test_ruby_build_dependencies(host, name):
        pkg = host.package(name)
        assert pkg.is_installed


    def test_ruby_executable_file(host):
        exe = host.file("/usr/local/bin/ruby")
        assert exe.user == "root"
        assert exe.group == "root"
        assert exe.mode == 0o755


    def test_ruby_command(host):
        cmd = host.check_output("/usr/local/bin/ruby -v")
        assert re.match("^ruby 2.7.1*", cmd)

You can see we are now testing for the Ruby executable and ensuring it
has the expected owner and permissions.  We also call the command and
use a regular expression to make sure that `ruby -v` returns the
version of Ruby we expect to `stdout`.

## Compile and Install Ruby

Our tests now cover the Ruby install itself so we can now add to our
Ansible code and make those tests pass.  Edit `tasks/main.yml` to
download the Ruby source code and then compile it from source, we can
also abstract out some of the details into default variables to make
the role more reusable.

    ---

    - name: install ruby build dependencies
      yum:
        name:
          - automake
          - bison
          - gcc
          - gdbm-devel
          - libffi-devel
          - libyaml-devel
          - ncurses-devel
          - openssl-devel
          - readline-devel
          - tar
          - zlib-devel

    - name: download ruby source code tarball
      get_url:
        url: http://cache.ruby-lang.org/pub/ruby/{{ ruby_minor_version }}/ruby-{{ ruby_minor_version }}.{{ ruby_teenie_version }}.tar.gz
        dest: /tmp/ruby-{{ ruby_minor_version }}.{{ruby_teenie_version }}.tar.gz
        sha256sum: "{{ ruby_sha256sum }}"

    - name: extract ruby source code tarball
      unarchive:
        src: /tmp/ruby-{{ ruby_minor_version }}.{{ ruby_teenie_version }}.tar.gz
        dest: /tmp
        copy: no

    - name: compile and install ruby
      command: "{{ item }}"
      with_items:
        - ./configure --prefix={{ ruby_prefix }}
        - make
        - make install
      args:
        chdir: /tmp/ruby-{{ ruby_minor_version }}.{{ ruby_teenie_version }}
        creates: "{{ ruby_prefix }}/bin/ruby"

We will of course also need to supply these variables in
`defaults/main.yml`:

    ---

    ruby_minor_version: 2.7
    ruby_teenie_version: 1
    ruby_sha256sum: d418483bdd0000576c1370571121a6eb24582116db0b7bb2005e90e250eae418
    ruby_prefix: /usr/local

## Testing Within the Ansible Run Itself

As mentioned in the introduction, many people within the Ansible
community believe it is uneccessary to write tests like we have been and
that if needed you should just write your tests into the Ansible run
itself.  Although we've already used TestInfra to test our Ruby install
let's look at how you might go about baking testing into the Ansible
run.  Back in the `tasks/main.yml` file add the following:

    # Override the "changed" result, we are not changing anything here, just
    # calling the ruby executable so we can check its version.
    #
    # Skip ansible-lint here as it will flag this as unecessary with the following:
    # [ANSIBLE0012] Commands should not change things if nothing needs doing
    - name: test ruby version
      command: "{{ ruby_prefix }}/bin/ruby -v"
      register: test_ruby_version
      changed_when: False
      tags:
        - skip_ansible_lint

    - name: assert ruby version
      assert:
        that:
          - "'ruby {{ ruby_minor_version }}.{{ ruby_teenie_version }}' in test_ruby_version.stdout"

You can see this is similar to what our TestInfra test does.  It calls
`ruby -v` at our installed location and makes sure the version we
expect is outputted to `stdout`.  Note that we skip the ansible-lint
by adding a tag, what we are doing here doesn't look quite right to
ansible-lint since we are not making changes to the system, rather we
are just calling a command to check its output.  We also need to tell
Ansible that even though this command will execute on all subsequent
Ansible runs we are not actually making a change to the system,
without the `changed_when` override Ansible would report this as
`changed` every time and the idempotence check would fail.

*Note* This style of testing is now the default in Molecule rather
than Testinfra.

## Refactor Tests for an Additional OS

Let's refactor our Ansible role so that it will work on both Amazon
Linux and Ubuntu.[^ubuntu]

Refactoring like this is less daunting now that we have tests even
when the Ansible code base starts getting larger and more complicated.

First off edit our `molecule/default/molecule.yml` to add in an extra
container image and give them sensible names to distinguish between
the two:

    ---
    dependency:
      name: galaxy
    driver:
      name: docker
    platforms:
      - name: amazonlinux
        image: amazonlinux
      - name: ubuntu
        image: ubuntu
    provisioner:
      name: ansible
    verifier:
      name: testinfra

The end result of our role is to install Ruby so most of our tests
will work no matter what the OS.  However, Debian based systems such
as Ubuntu have different package names for the build dependencies
which we need to accomodate for.  First let's modify our tests to
check for specific packages depending on the OS.  In order to separate
out our OS specific tests, create a new directory and file at
`molecule/default/tests/test_amazonlinux.py` with the following:

    import pytest

    testinfra_hosts = ["amazonlinux"]


    @pytest.mark.parametrize("name", [
        ("automake"),
        ("bison"),
        ("gcc"),
        ("gzip"),
        ("gdbm-devel"),
        ("libffi-devel"),
        ("libyaml-devel"),
        ("make"),
        ("ncurses-devel"),
        ("openssl-devel"),
        ("readline-devel"),
        ("tar"),
        ("zlib-devel"),
    ])
    def test_amazon_ruby_build_dependencies(host, name):
        pkg = host.package(name)
        assert pkg.is_installed

We need to create a similar file to test for the different package names
on Ubuntu at `molecule/default/tests/test_ubuntu.py`:

    import pytest

    testinfra_hosts = ["ubuntu"]

    @pytest.mark.parametrize("name", [
        "automake",
        "bison",
        "build-essential",
        "gzip",
        "libffi-dev",
        "libgdbm-dev",
        "libncurses-dev",
        "libreadline-dev",
        "libssl-dev",
        "libyaml-dev",
        "make",
        "tar",
        "zlib1g-dev",
    ])
    def test_ubuntu_ruby_build_dependencies(host, name):
        pkg = host.package(name)
        assert pkg.is_installed

Remove the similar section from
`molecule/default/tests/test_default.py` as these are now going to be
common tests that will run on both containers / operating systems;
also remove the `import pytest` line as it is not used now and it will
be picked up by the linter.

## Update Ansible for Debian Based Systems

Now that our tests now work with both Amazon Linux (RHEL--like) and
Ubuntu (Debian--like) we need to modify our Ansible slightly to cater for
the differing package names.  We can achieve this by using Ansible's
`when` conditional, in `tasks/main.yml` replace the current ruby
dependencies task with:

    # RHEL-like operating systems such as Amazon Linux.
    - name: install ruby build dependencies
      when: ansible_os_family == "RedHat"
      package:
        name:
          - automake
          - bison
          - gcc
          - gdbm-devel
          - gzip
          - libffi-devel
          - libyaml-devel
          - make
          - ncurses-devel
          - openssl-devel
          - readline-devel
          - tar
          - zlib-devel

    # Debian-like operating systems such as Ubuntu.
    - name: install ruby build dependencies
      when: ansible_os_family == "Debian"
      package:
        name:
          - automake
          - bison
          - build-essential
          - gzip
          - libffi-dev
          - libgdbm-dev
          - libncurses-dev
          - libreadline-dev
          - libssl-dev
          - libyaml-dev
          - make
          - tar
          - zlib1g-dev

We should be able to do a `molecule test` again and all tests should
pass but this time we spin up two different OS containers
simultaneously.  Make sure to destroy any current running containers
with `molecule destroy` if you've not done so since modifying
`molecule/default/molecule.yml`.

## Refactor Packages into Variables

I know that a lot of people would cleanup the two `install ruby build
dependencies` tasks by setting the list of packages within variables
instead.  Just to illustrate how writing tests gives us the confidence
to refactor as much as we like let's try doing just that by creating a
`vars/main.yml` with:

    ---

    redhat_pkgs:
      - automake
      - bison
      - gcc
      - gdbm-devel
      - gzip
      - libffi-devel
      - libyaml-devel
      - make
      - ncurses-devel
      - openssl-devel
      - readline-devel
      - tar
      - zlib-devel

    debian_pkgs:
      - automake
      - bison
      - build-essential
      - gzip
      - libffi-dev
      - libgdbm-dev
      - libncurses-dev
      - libreadline-dev
      - libssl-dev
      - libyaml-dev
      - make
      - tar
      - zlib1g-dev

Now amend our tasks in `tasks/main.yml` to use these variables:

    # RHEL-like operating systems such as Amazon Linux.
    - name: install ruby build dependencies
      when: ansible_os_family == "RedHat"
      package:
        name: "{{ redhat_pkgs }}"

    # Debian-like operating systems such as Ubuntu.
    - name: install ruby build dependencies
      when: ansible_os_family == "Debian"
      package:
        name: "{{ debian_pkgs }}"

Confirm all is well by running the test suite again.

## Conclusion

I hope this post has got you interested in testing your Ansible code
more and has shown how easy it is to get started.  Although this does
not seem widely done in the Ansible community personally I really like
this way of working and testing can only improve the Ansible roles I
write.

## Footnotes

[^test-kitchen]:
    You can actually use Test Kitchen to test other configuration
    management tools such as Ansible, Salt, Puppet etc.

[^venv]:
    [https://docs.python.org/3/library/venv.html](https://docs.python.org/3/library/venv.html)

[^dry]:
    [Don't Repeat Yourself](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself)

[^ubuntu]:
    It should actually work with many RHEL or Debian like operating
    systems once complete.
