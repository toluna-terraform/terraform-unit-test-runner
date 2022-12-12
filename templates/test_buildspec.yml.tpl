version: 0.2

env:
  parameter-store:
    CONSUL_URL: "/infra/consul_url"
    CONSUL_HTTP_TOKEN: "/infra/consul_http_token"
    GITHUB_TOKEN: "/app/github_token"

phases:
  install:
    runtime-versions:
      docker: 18
  pre_build:
    commands:
      - yum -y install yum-utils
      - yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
      - yum -y install wget jq terraform consul 
      - export CONSUL_HTTP_ADDR=https://$CONSUL_URL
      - wget -nv https://go.dev/dl/go1.18.linux-amd64.tar.gz
      - rm -rf /usr/local/go && tar -C /usr/local -xzf go1.18.linux-amd64.tar.gz
      - export PATH=$PATH:/usr/local/go/bin
      - export GOPATH=~/go
      - export GOVERSION=go1.18.1
      - export GO_INSTALL_DIR=/usr/local/go
      - export GOROOT=$GO_INSTALL_DIR
      - export GOPATH=/home/ec2-user/golang
      - export PATH=$GOROOT/bin:$GOPATH/bin:$PATH
      - export GO111MODULE="on"
      - export GOSUMDB=off
      - go install gotest.tools/gotestsum@latest
      - go install github.com/boumenot/gocover-cobertura@latest
      - |
        cd $CODEBUILD_SRC_DIR/tests
        go mod init "${MODULE_PATH}"
        go mod tidy
  build:
    commands:
      - |
        cd $CODEBUILD_SRC_DIR/tests
        gotestsum --junitfile reports/report.xml --format testname
        gocover-cobertura < reports/cover.out > reports/coverage.xml
  post_build:
    commands:
      - | 
        export UTS="FAIL" 
        export CTS="PASS"
        grep message=\"Failed\" $CODEBUILD_SRC_DIR/tests/reports/report.xml || export UTS="PASS"
        grep 'coverage line-rate="1"' $CODEBUILD_SRC_DIR/tests/reports/coverage.xml || export CTS="FAIL"
        if [[ "$UTS" == "PASS" ]] && [[ "$CTS" == "PASS" ]]; then
          echo "Tests passed waiting for pull request approval..."
        else
          echo "Unit test status::::$UTS"
          echo "Coverege test status::::$CTS"
          exit 1
        fi

reports:
  ${MODULE_NAME}-unitTest:
    files:
      - '**/reports/report.xml'
    file-format: JunitXml
  ${MODULE_NAME}-Testcoverege:
    files:
      - '**/reports/coverage.xml'
    file-format: COBERTURAXML
  
