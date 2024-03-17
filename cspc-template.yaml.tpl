apiVersion: cstor.openebs.io/v1
kind: CStorPoolCluster
metadata:
  name: cspc-disk-pool
  namespace: openebs
spec:
  pools:
%{ for node in nodes ~}
  - nodeSelector:
      kubernetes.io/hostname: "${node.name}"
    dataRaidGroups:
    - blockDevices:
%{ for bd in node.block_devices ~}
      - blockDeviceName: "${bd}"
%{ endfor }
    poolConfig:
      dataRaidGroupType: "stripe"
      defaultRaidGroupType: "stripe"
      cacheFile: ""
      compression: "off"
      overProvisioning: true
%{ endfor }