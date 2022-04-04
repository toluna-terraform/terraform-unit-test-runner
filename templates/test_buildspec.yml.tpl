version: 0.2

env:
  parameter-store:
    CONSUL_PROJECT_ID: "/infra/consul_project_id"
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
      - export CONSUL_HTTP_ADDR=https://consul-cluster-test.consul.$CONSUL_PROJECT_ID.aws.hashicorp.cloud
      - wget -nv https://go.dev/dl/go1.17.linux-amd64.tar.gz
      - rm -rf /usr/local/go && tar -C /usr/local -xzf go1.17.linux-amd64.tar.gz
      - export PATH=$PATH:/usr/local/go/bin
      - export GOPATH=~/go
      - go get gotest.tools/gotestsum
      - sudo mv ~/go/bin/gotestsum /usr/local/bin
      - go get github.com/boumenot/gocover-cobertura
      - sudo mv ~/go/bin/gocover-cobertura /usr/local/bin
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
  
