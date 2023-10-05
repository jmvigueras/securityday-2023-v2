name: FortiDevSec Scanner CI 
on:
  push:
   branches: [ master ]
  pull_request:
   branches: [ master ]
 
jobs:  
  scanning:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: SAST
      run: |
       docker pull registry.fortidevsec.forticloud.com/fdevsec_sast:latest
       docker run -i --mount type=bind,source="$(pwd)",target=/scan  registry.fortidevsec.forticloud.com/fdevsec_sast:latest
  
  kubescape:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: kubescape/github-action@main
        continue-on-error: true
        with:
          format: sarif
          outputFile: results.sarif
          files: "manifest/*.yaml"

${deploy_k8s}