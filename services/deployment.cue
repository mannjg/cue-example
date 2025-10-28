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
		{name: "http", containerPort: 8080, protocol: "TCP"},
	]
	_debugContainerPorts: [...k8s.#ContainerPort]
	if appConfig.debug {
		_debugContainerPorts: [{name: "debug", containerPort: 5005, protocol: "TCP"}]
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
			let cacheSettings = _volumeConfig.cacheVolumeSettings | *{}
			{
				name: "cache"
				emptyDir: {
					medium:    cacheSettings.medium | *"Memory"
					sizeLimit: cacheSettings.sizeLimit | *"256Mi"
				}
			}
		},
	]

	_projectedSecretsVolumes: [
		if (_volumeConfig.enableProjectedSecretsVolume | *true) {
			let projConfig = _volumeConfig.projectedSecretsConfig | *{}
			let secretItems = projConfig.secretItems | *[
				{key: "db-user", path: "database/username"},
				{key: "db-password", path: "database/password"},
			]
			let configMapItems = projConfig.configMapItems | *[
				{key: "redis-url", path: "config/redis-url"},
			]
			let clusterCAItems = projConfig.clusterCAItems | *[
				{key: "ca.crt", path: "config/cluster-ca.crt"},
			]
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
					defaultMode: 0o400
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
								items: [
									{path: "pod/name", fieldRef: fieldPath:        "metadata.name"},
									{path: "pod/namespace", fieldRef: fieldPath:   "metadata.namespace"},
								]
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
			{name: "data", mountPath: "/var/lib/myapp/data", readOnly: false}
		},
	]

	_configVolumeMounts: [
		if (_volumeConfig.enableConfigVolume | *true) {
			{name: "config", mountPath: "/etc/myapp/config", readOnly: true}
		},
	]

	_cacheVolumeMounts: [
		if (_volumeConfig.enableCacheVolume | *true) {
			{name: "cache", mountPath: "/var/cache/myapp", readOnly: false}
		},
	]

	_projectedSecretsVolumeMounts: [
		if (_volumeConfig.enableProjectedSecretsVolume | *true) {
			{name: "projected-secrets", mountPath: "/var/secrets", readOnly: true}
		},
	]

	_additionalVolumeMounts: _volumeConfig.additionalVolumeMounts | *[]

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
				strategy: {
					type: "RollingUpdate"
					rollingUpdate: {
						maxSurge:       1
						maxUnavailable: 1
					}
				}
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

						resources: appConfig.resources

						// Liveness probe with smart defaults - merges user settings with defaults
						_defaultLivenessProbe: {
							httpGet: {
								path:   "/health/live"
								port:   8080
								scheme: "HTTP"
							}
							initialDelaySeconds: 30
							periodSeconds:       10
							timeoutSeconds:      5
							failureThreshold:    3
						}
						livenessProbe: _defaultLivenessProbe & (appConfig.livenessProbe | {})

						// Readiness probe with smart defaults - merges user settings with defaults
						_defaultReadinessProbe: {
							httpGet: {
								path:   "/health/ready"
								port:   8080
								scheme: "HTTP"
							}
							initialDelaySeconds: 10
							periodSeconds:       5
							timeoutSeconds:      3
							failureThreshold:    3
						}
						readinessProbe: _defaultReadinessProbe & (appConfig.readinessProbe | {})

						securityContext: {
							runAsNonRoot:             true
							runAsUser:                1000
							runAsGroup:               1000
							readOnlyRootFilesystem:   false
							allowPrivilegeEscalation: false
							capabilities: drop: ["ALL"]
						}
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

					securityContext: {
						runAsNonRoot: true
						runAsUser:    1000
						runAsGroup:   1000
						fsGroup:      1000
					}

					serviceAccountName: appName
				}
			}
		}
	}
}
