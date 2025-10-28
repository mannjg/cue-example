// Package services provides shared application templates and patterns
// This file defines the Deployment resource template
package services

import (
	"list"

	"example.com/cue-example/k8s"
)

// #DeploymentTemplate generates a Kubernetes Deployment from app configuration.
// This is a pure template that takes appName and appConfig and produces a Deployment.
#DeploymentTemplate: {
	// Required inputs
	appName:   string
	appConfig: #AppConfig

	// Resource manifest - this template always produces a deployment
	_producedResources: ["deployment"]

	// Default labels (can be extended via appConfig.labels)
	_defaultLabels: {
		app:        appName
		deployment: appName
	}

	// Computed labels - merge defaults with config
	_labels: _defaultLabels & appConfig.labels

	// Default environment variables (apps can extend via appConfig.additionalEnv)
	_defaultEnv: [...k8s.#EnvVar]
	if appConfig.debug {
		_defaultEnv: [{name: "DEBUG", value: "yes"}]
	}
	if !appConfig.debug {
		_defaultEnv: []
	}

	// Computed env - merge defaults with additional
	_env: list.Concat([_defaultEnv, appConfig.additionalEnv])

	// Default envFrom sources (apps can extend via appConfig.additionalEnvFrom)
	_defaultEnvFrom: []

	// Computed envFrom - merge defaults with additional
	_envFrom: list.Concat([_defaultEnvFrom, appConfig.additionalEnvFrom])

	// Container ports - always include base ports, plus debug when enabled, plus additional
	_baseContainerPorts: [
		#DefaultHttpContainerPort,
	]
	_debugContainerPorts: [...k8s.#ContainerPort]
	if appConfig.debug {
		_debugContainerPorts: [#DefaultDebugContainerPort]
	}
	if !appConfig.debug {
		_debugContainerPorts: []
	}
	_containerPorts: list.Concat([_baseContainerPorts, _debugContainerPorts, appConfig.additionalContainerPorts])

	// Volume configuration with smart defaults
	_volumeConfig: appConfig.volumes | *{}

	// Build volumes list based on configuration
	_volumes: list.Concat([
		_dataVolumes,
		_configVolumes,
		_cacheVolumes,
		_projectedSecretsVolumes,
		_appConfigMapVolumes,
		_additionalVolumes,
	])

	_dataVolumes: [
		if (_volumeConfig.enableDataVolume | *true) {
			name: "data"
			persistentVolumeClaim: {
				claimName: _volumeConfig.dataVolumePVCName | *"\(appName)-data"
			}
		},
	]

	_configVolumes: [
		if (_volumeConfig.enableConfigVolume | *true) {
			name: "config"
			configMap: {
				name: _volumeConfig.configVolumeConfigMapName | *"\(appName)-config"
			}
		},
	]

	_cacheVolumes: [
		if (_volumeConfig.enableCacheVolume | *true) {
			let cacheSettings = _volumeConfig.cacheVolumeSettings | *#DefaultCacheVolumeSettings
			{
				name: "cache"
				emptyDir: {
					medium:    cacheSettings.medium
					sizeLimit: cacheSettings.sizeLimit
				}
			}
		},
	]

	_projectedSecretsVolumes: [
		if (_volumeConfig.enableProjectedSecretsVolume | *true) {
			let projConfig = _volumeConfig.projectedSecretsConfig | *{}
			let secretItems = projConfig.secretItems | *#DefaultProjectedSecretItems
			let configMapItems = projConfig.configMapItems | *#DefaultProjectedConfigMapItems
			let clusterCAItems = projConfig.clusterCAItems | *#DefaultProjectedClusterCAItems
			let includeDownwardAPI = projConfig.includeDownwardAPI | *true

			let volumeSourceNames = {
				if appConfig.volumeSourceNames != _|_ && appConfig.volumeSourceNames.configMapName != _|_ {
					configMapName: appConfig.volumeSourceNames.configMapName
				}
				if appConfig.volumeSourceNames == _|_ || appConfig.volumeSourceNames.configMapName == _|_ {
					configMapName: "\(appName)-config"
				}
				if appConfig.volumeSourceNames != _|_ && appConfig.volumeSourceNames.secretName != _|_ {
					secretName: appConfig.volumeSourceNames.secretName
				}
				if appConfig.volumeSourceNames == _|_ || appConfig.volumeSourceNames.secretName == _|_ {
					secretName: "\(appName)-secrets"
				}
			}
			{
				name: "projected-secrets"
				projected: {
					defaultMode: #DefaultProjectedVolumeMode
					sources: [
						if len(secretItems) > 0 {
							secret: {
								name:  volumeSourceNames.secretName
								items: secretItems
							}
						},
						if len(configMapItems) > 0 {
							configMap: {
								name:  volumeSourceNames.configMapName
								items: configMapItems
							}
						},
						if len(clusterCAItems) > 0 {
							if appConfig.clusterCAConfigMap != _|_ {
								configMap: {
									name:  appConfig.clusterCAConfigMap
									items: clusterCAItems
								}
							}
							if appConfig.clusterCAConfigMap == _|_ {
								configMap: {
									name:  "\(appName)-cluster-ca"
									items: clusterCAItems
								}
							}
						},
						if includeDownwardAPI {
							downwardAPI: {
								items: #DefaultDownwardAPIItems
							}
						},
					]
				}
			}
		},
	]

	_additionalVolumes: _volumeConfig.additionalVolumes | *[]

	// App-specific ConfigMap volume (when configMapData is provided)
	_appConfigMapVolumes: [
		if appConfig.configMapData != _|_ {
			name: #DefaultAppConfigMapVolumeName
			configMap: {
				name: "\(appName)-config"
				if appConfig.configMapData.mount != _|_ && appConfig.configMapData.mount.items != _|_ {
					items: appConfig.configMapData.mount.items
				}
			}
		},
	]

	// Build volume mounts list
	_volumeMounts: list.Concat([
		_dataVolumeMounts,
		_configVolumeMounts,
		_cacheVolumeMounts,
		_projectedSecretsVolumeMounts,
		_appConfigMapVolumeMounts,
		_additionalVolumeMounts,
	])

	_dataVolumeMounts: [
		if (_volumeConfig.enableDataVolume | *true) {
			#DefaultDataVolumeMount
		},
	]

	_configVolumeMounts: [
		if (_volumeConfig.enableConfigVolume | *true) {
			#DefaultConfigVolumeMount
		},
	]

	_cacheVolumeMounts: [
		if (_volumeConfig.enableCacheVolume | *true) {
			#DefaultCacheVolumeMount
		},
	]

	_projectedSecretsVolumeMounts: [
		if (_volumeConfig.enableProjectedSecretsVolume | *true) {
			#DefaultProjectedSecretsVolumeMount
		},
	]

	_additionalVolumeMounts: _volumeConfig.additionalVolumeMounts | *[]

	// App-specific ConfigMap volume mounts (when configMapData is provided)
	_appConfigMapVolumeMounts: [
		if appConfig.configMapData != _|_ {
			let mountConfig = appConfig.configMapData.mount | *{}
			{
				name:      #DefaultAppConfigMapVolumeName
				mountPath: mountConfig.path | #DefaultAppConfigMapVolumeMount.mountPath
				readOnly:  mountConfig.readOnly | #DefaultAppConfigMapVolumeMount.readOnly
				if mountConfig.subPath != _|_ {
					subPath: mountConfig.subPath
				}
			}
		},
	]

	// The actual Deployment resource
	deployment: k8s.#Deployment & {
		metadata: {
			name:      appName
			namespace: appConfig.namespace
			labels:    _labels
			if appConfig.deploymentAnnotations != _|_ {
				annotations: appConfig.deploymentAnnotations
			}
		}

		spec: {
			replicas: appConfig.replicas

			selector: matchLabels: _labels

			// Deployment strategy with defaults
			if appConfig.deploymentStrategy != _|_ {
				strategy: appConfig.deploymentStrategy
			}
			if appConfig.deploymentStrategy == _|_ {
				strategy: #DefaultDeploymentStrategy
			}

			template: {
				metadata: {
					labels: _labels
					if appConfig.podAnnotations != _|_ {
						annotations: appConfig.podAnnotations
					}
				}

				spec: {
					containers: [{
						name:            appName
						image:           appConfig.image
						imagePullPolicy: "Always"

						if len(_env) > 0 {
							env: _env
						}

						envFrom: _envFrom

						ports: _containerPorts

						volumeMounts: _volumeMounts

						// Only include resources if defined (avoids rendering empty resources: {})
						if appConfig.resources != _|_ {
							resources: appConfig.resources
						}

						// Liveness probe with smart defaults - merges user settings with defaults
						livenessProbe: #DefaultLivenessProbe & (appConfig.livenessProbe | {})

						// Readiness probe with smart defaults - merges user settings with defaults
						readinessProbe: #DefaultReadinessProbe & (appConfig.readinessProbe | {})

						securityContext: #DefaultContainerSecurityContext
					}]

					volumes: _volumes

					if appConfig.nodeSelector != _|_ {
						nodeSelector: appConfig.nodeSelector
					}

					if appConfig.priorityClassName != _|_ {
						priorityClassName: appConfig.priorityClassName
					}

					if appConfig.affinity != _|_ {
						affinity: appConfig.affinity
					}

					securityContext: #DefaultPodSecurityContext

					serviceAccountName: appName
				}
			}
		}
	}
}
