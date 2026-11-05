.PHONY: help bootstrap bootstrap-dev build serve clean distclean

help:
	@echo "make bootstrap        # create venv + install doc dependencies"
	@echo "make bootstrap-dev    # install dev doc extras"
	@echo "make build            # build documentation with mkdocs"
	@echo "make serve            # mkdocs live-reload dev server on :8000"
	@echo "make clean            # remove build artifacts"
	@echo "make distclean        # clean + remove .venv"

bootstrap:
	./scripts/bootstrap.sh

bootstrap-dev:
	./scripts/bootstrap.sh --dev

build:
	./scripts/build.sh

serve:
	./scripts/serve.sh

clean:
	./scripts/clean.sh

distclean:
	./scripts/clean.sh --all --venv
