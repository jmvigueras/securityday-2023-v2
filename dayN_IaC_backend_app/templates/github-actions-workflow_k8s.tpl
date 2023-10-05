  
  
  ${prefix}k8s:
    name: Deploy_${prefix}k8s
    runs-on: ubuntu-latest
    needs: kubescape
    steps:
    - uses: actions/checkout@v4
    - uses: actions-hub/kubectl@master
      env:
        KUBE_TOKEN: $${{ secrets.${prefix}KUBE_TOKEN }}
        KUBE_HOST: $${{ secrets.${prefix}KUBE_HOST }}
        KUBE_CERTIFICATE: $${{ secrets.${prefix}KUBE_CERTIFICATE }}
      with:
        # First deployment
        args: apply -f manifest/*.yaml
        # First deployment without checking API CA certificate
        # args: --insecure-skip-tls-verify apply -f manifest/*.yaml
        # Used if previous deployment exists
        # args: --insecure-skip-tls-verify set image deployment/${app_name}-deployment  ${app_name}=${dockerhub_username}/${dockerhub_image_name}:$${{ github.run_id }}
        # args: set image deployment/${app_name}-deployment ${app_name}=${dockerhub_username}/${dockerhub_image_name}:$${{ github.run_id }}