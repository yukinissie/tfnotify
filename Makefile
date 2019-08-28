PACKAGES := $(shell go list ./...)
COMMIT = $$(git describe --tags --always)
DATE = $$(date -u '+%Y-%m-%d_%H:%M:%S')
BUILD_LDFLAGS = -X $(PKG).commit=$(COMMIT) -X $(PKG).date=$(DATE)
RELEASE_BUILD_LDFLAGS = -s -w $(BUILD_LDFLAGS)

.PHONY: all
all: test

.PHONY: build
build:
	GO111MODULE=on go build

.PHONY: crossbuild
crossbuild:
	$(eval version = $(shell gobump show -r))
	goxz -pv=v$(version) -os=linux,darwin -arch=386,amd64 -build-ldflags="$(RELEASE_BUILD_LDFLAGS)" \
	  -d=./dist/v$(version)

.PHONY: test
test:
	GO111MODULE=on go test -v -parallel=4 ./...

.PHONY: dep
dep:
	GO111MODULE=on go mod download

.PHONY: reviewdog
reviewdog: devel-deps
	reviewdog -reporter="github-pr-review"

.PHONY: coverage
coverage: devel-deps
	goverage -v -covermode=atomic -coverprofile=coverage.txt $(PACKAGES)

.PHONY: release
release:
	@./misc/scripts/bump-and-chglog.sh
	@./misc/scripts/upload-artifacts.sh

.PHONY: devel-deps
devel-deps:
	@go get -v -u github.com/Songmu/ghch/cmd/ghch
	@go get -v -u github.com/Songmu/goxz/cmd/goxz
	@go get -v -u github.com/git-chglog/git-chglog/cmd/git-chglog
	@go get -v -u golang.org/x/lint/golint
	@go get -v -u github.com/haya14busa/goverage
	@go get -v -u github.com/haya14busa/reviewdog/cmd/reviewdog
	@go get -v -u github.com/motemen/gobump/cmd/gobump
	@go get -v -u github.com/tcnksm/ghr
