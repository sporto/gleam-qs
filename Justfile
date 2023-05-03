test:
	gleam test

publish:
	rebar3 hex publish

docs:
	gleam docs build --version 0.2.0

docs-preview:
	sfz -r ./gen/docs/

docs-publish:
	gleam docs publish --version 0.1.0 .