all: clean build

build: dst/*

dst/*:
	./ssg src dst '#!/Hash/Bang/Wallop' 'https://hashbangwallop.com'
	./rssg src/index.md '#!/Hash/Bang/Wallop' > dst/rss.xml

lint:
	yarn stylelint "src/css/*.css"

lint-fix:
	yarn stylelint --fix "src/css/*.css"

publish:
	aws --profile rosstimson s3 sync dst s3://hashbangwallop.com/
	aws --profile rosstimson cloudfront create-invalidation --distribution-id E1ZL32K36QWTLW --paths '/*'

# For some reason when run via 'make' the hidden file doesn't get
# remove via 'rm -rf dst/*' even though it normally would
clean:
	@rm -rf dst/.files
	@rm -rf dst/*


.PHONY: all build clean lint lint-fix publish
