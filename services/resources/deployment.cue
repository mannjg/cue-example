// Package services provides shared application templates and patterns
// This file defines the Deployment resource template
package resources

import (
	"list"

	"example.com/cue-example/k8s"
	base "example.com/cue-example/services/base"
)

// #DeploymentTemplate generates a Kubernetes Deployment from app configuration.
// This is a pure template that takes appName and appConfig and produces a Deployment.
#DeploymentTemplate: {
	// Required inputs
	appName:   string
	appConfig: base.#AppConfig

	// Optional: app-level environment variables (provided by app.cue)
	appEnvVars: [...k8s.#EnvVar] | *[]

	// Optional: app-level envFrom sources (provided by app.cue)
	appEnvFrom: [...k8s.#EnvFromSource] | *[]

	// Default labels (can be extended via appConfig.labels)
	_defaultLabels: {
		app:        appName
		deployment: appName
	}

	// Computed labels - merge defaults with config
	_labels: _defaultLabels & appConfig.labels

	// Computed env - concatenate: app-level defaults + environment-specific
	// Note: appEnvVars includes system defaults (like DEBUG) computed in app.cue
	_env: list.Concat([appEnvVars, appConfig.deployment.additionalEnv])

	// Computed envFrom - concatenate: app-level + environment-specific
	// Note: appEnvFrom includes app-level and environment-level envFrom computed in app.cue
	_envFrom: list.Concat([appEnvFrom, appConfig.deployment.additionalEnvFrom])

	// Container ports - always include base ports, plus debug when enabled, plus additional
	_baseContainerPorts: [...k8s.#ContainerPort]
	if appConfig.enableHttps {
		_baseContainerPorts: [base.#DefaultHttpsContainerPort]
	}
	if !appConfig.enableHttps {
		_baseContainerPorts: [base.#DefaultHttpContainerPort]
	}
	_debugContainerPorts: [...k8s.#ContainerPort]
	if appConfig.debug {
		_debugContainerPorts: [base.#DefaultDebugContainerPort]
	}
	if !appConfig.debug {
		_debugContainerPorts: []
	}
	_containerPorts: list.Concat([_baseContainerPorts, _debugContainerPorts, appConfig.deployment.additionalPorts])

	// Volume configuration with smart defaults
	_volumeConfig: appConfig.deployment.volumes | *{}

	// Build volumes list based on configuration
	_volumes: list.Concat([
		_dataVolumes,
		_configVolumes,
		_cacheVolumes,
		_projectedSecretsVolumes,
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
		// Config volume is enabled if:
		// 1. Explicitly enabled via volumeConfig.enableConfigVolume, OR
		// 2. configMap is provided (which auto-creates the ConfigMap)
		if (_volumeConfig.enableConfigVolume | *true) || (appConfig.configMap != _|_) {
			name: "config"
			configMap: {
				name: _volumeConfig.configVolumeConfigMapName | *"\(appName)-config"
				// If configMap provides specific items to mount, use those
				if appConfig.configMap != _|_ && appConfig.configMap.mount != _|_ && appConfig.configMap.mount.items != _|_ {
					items: appConfig.configMap.mount.items
				}
			}
		},
	]

	_cacheVolumes: [
		if (_volumeConfig.enableCacheVolume | *true) {
			let cacheSettings = _volumeConfig.cacheVolumeSettings | *base.#DefaultCacheVolumeSettings
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
			let secretItems = projConfig.secretItems | *base.#DefaultProjectedSecretItems
			let configMapItems = projConfig.configMapItems | *base.#DefaultProjectedConfigMapItems
			let clusterCAItems = projConfig.clusterCAItems | *base.#DefaultProjectedClusterCAItems
			let includeDownwardAPI = projConfig.includeDownwardAPI | *true

			let volumeSourceNames = {
				if appConfig.deployment.volumeSourceNames != _|_ && appConfig.deployment.volumeSourceNames.configMapName != _|_ {
					configMapName: appConfig.deployment.volumeSourceNames.configMapName
				}
				if appConfig.deployment.volumeSourceNames == _|_ || appConfig.deployment.volumeSourceNames.configMapName == _|_ {
					configMapName: "\(appName)-config"
				}
				if appConfig.deployment.volumeSourceNames != _|_ && appConfig.deployment.volumeSourceNames.secretName != _|_ {
					secretName: appConfig.deployment.volumeSourceNames.secretName
				}
				if appConfig.deployment.volumeSourceNames == _|_ || appConfig.deployment.volumeSourceNames.secretName == _|_ {
					secretName: "\(appName)-secrets"
				}
			}
			{
				name: "projected-secrets"
				projected: {
					defaultMode: base.#DefaultProjectedVolumeMode
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
							if appConfig.deployment.clusterCAConfigMap != _|_ {
								configMap: {
									name:  appConfig.deployment.clusterCAConfigMap
									items: clusterCAItems
								}
							}
							if appConfig.deployment.clusterCAConfigMap == _|_ {
								configMap: {
									name:  "\(appName)-cluster-ca"
									items: clusterCAItems
								}
							}
						},
						if includeDownwardAPI {
							downwardAPI: {
								items: base.#DefaultDownwardAPIItems
							}
						},
					]
				}
			}
		},
	]

	_additionalVolumes: _volumeConfig.additionalVolumes | *[]

	// Build volume mounts list
	_volumeMounts: list.Concat([
		_dataVolumeMounts,
		_configVolumeMounts,
		_cacheVolumeMounts,
		_projectedSecretsVolumeMounts,
		_additionalVolumeMounts,
	])

	_dataVolumeMounts: [
		if (_volumeConfig.enableDataVolume | *true) {
			base.#DefaultDataVolumeMount
		},
	]

	_configVolumeMounts: [
		// Config volume mount is enabled if:
		// 1. Explicitly enabled via volumeConfig.enableConfigVolume, OR
		// 2. configMap is provided (which auto-creates the ConfigMap)
		if (_volumeConfig.enableConfigVolume | *true) || (appConfig.configMap != _|_) {
			// If configMap provides mount config, use it; otherwise use defaults
			if appConfig.configMap != _|_ && appConfig.configMap.mount != _|_ {
				let mountConfig = appConfig.configMap.mount
				{
					name:      "config"
					mountPath: mountConfig.path | *base.#DefaultConfigVolumeMount.mountPath
					readOnly:  mountConfig.readOnly | *base.#DefaultConfigVolumeMount.readOnly
					if mountConfig.subPath != _|_ {
						subPath: mountConfig.subPath
					}
				}
			}
			if appConfig.configMap == _|_ || appConfig.configMap.mount == _|_ {
				base.#DefaultConfigVolumeMount
			}
		},
	]

	_cacheVolumeMounts: [
		if (_volumeConfig.enableCacheVolume | *true) {
			base.#DefaultCacheVolumeMount
		},
	]

	_projectedSecretsVolumeMounts: [
		if (_volumeConfig.enableProjectedSecretsVolume | *true) {
			base.#DefaultProjectedSecretsVolumeMount
		},
	]

	_additionalVolumeMounts: _volumeConfig.additionalVolumeMounts | *[]

	// The actual Deployment resource
	deployment: k8s.#Deployment & {
		metadata: {
			name:      appName
			namespace: appConfig.namespace
			labels:    _labels
			if appConfig.deployment.annotations != _|_ {
				annotations: appConfig.deployment.annotations
			}
		}

		spec: {
			replicas: appConfig.deployment.replicas

			selector: matchLabels: _labels

			// Deployment strategy with defaults
			if appConfig.deployment.strategy != _|_ {
				strategy: appConfig.deployment.strategy
			}
			if appConfig.deployment.strategy == _|_ {
				strategy: base.#DefaultDeploymentStrategy
			}

			template: {
				metadata: {
					labels: _labels
					if appConfig.deployment.podAnnotations != _|_ {
						annotations: appConfig.deployment.podAnnotations
					}
				}

				spec: {
					containers: [{
						name:            appName
						image:           appConfig.deployment.image
						imagePullPolicy: "Always"

						if len(_env) > 0 {
							env: _env
						}

						envFrom: _envFrom

						ports: _containerPorts

						volumeMounts: _volumeMounts

						// Only include resources if defined (avoids rendering empty resources: {})
						if appConfig.deployment.resources != _|_ {
							resources: appConfig.deployment.resources
						}

						// Liveness probe with smart defaults - merges user settings with defaults
						if appConfig.enableHttps {
							livenessProbe: base.#DefaultHttpsLivenessProbe & (appConfig.deployment.livenessProbe | {})
						}
						if !appConfig.enableHttps {
							livenessProbe: base.#DefaultLivenessProbe & (appConfig.deployment.livenessProbe | {})
						}

						// Readiness probe with smart defaults - merges user settings with defaults
						if appConfig.enableHttps {
							readinessProbe: base.#DefaultHttpsReadinessProbe & (appConfig.deployment.readinessProbe | {})
						}
						if !appConfig.enableHttps {
							readinessProbe: base.#DefaultReadinessProbe & (appConfig.deployment.readinessProbe | {})
						}

						securityContext: base.#DefaultContainerSecurityContext
					}]

					volumes: _volumes

					if appConfig.deployment.nodeSelector != _|_ {
						nodeSelector: appConfig.deployment.nodeSelector
					}

					if appConfig.deployment.priorityClassName != _|_ {
						priorityClassName: appConfig.deployment.priorityClassName
					}

					if appConfig.deployment.affinity != _|_ {
						affinity: appConfig.deployment.affinity
					}

					securityContext: base.#DefaultPodSecurityContext

					serviceAccountName: appName
				}
			}
		}
	}
}
