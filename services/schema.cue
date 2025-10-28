// Package services provides shared application templates and patterns
// This file defines the configuration schema for applications
package services

import "example.com/cue-example/k8s"

// #AppConfig defines the complete schema for application configuration.
// All configuration should flow through this interface - environments provide
// these values, and they are used to render Kubernetes resources.
// This eliminates the need for deep merging of deployment/service structures.
#AppConfig: {
	// ===== Required Configuration =====
	// These must be provided by environment files

	// Container image with tag (e.g., "myapp:v1.2.3")
	image: string

	// Number of pod replicas
	replicas: int & >=1 & <=10

	// Resource requests and limits
	resources: k8s.#Resources

	// ===== Namespace and Identity =====

	// Namespace for all resources
	// Defaults to appNamespace if not specified
	namespace: string

	// Labels applied to all resources
	// Merged with defaultLabels from the app
	labels: [string]: string

	// ===== Deployment Configuration =====

	// Deployment-level annotations (applied to Deployment metadata)
	deploymentAnnotations?: [string]: string

	// Pod-level annotations (applied to Pod template metadata)
	podAnnotations?: [string]: string

	// Deployment strategy configuration
	// Controls how rolling updates are performed
	deploymentStrategy?: {
		type: *"RollingUpdate" | "Recreate"
		if type == "RollingUpdate" {
			rollingUpdate?: {
				maxSurge:       int | string | *1
				maxUnavailable: int | string | *1
			}
		}
	}

	// Priority class name for pod scheduling
	// Higher priority pods are scheduled before lower priority ones
	priorityClassName?: string

	// Affinity rules for advanced pod scheduling
	// Can specify pod affinity, anti-affinity, and node affinity
	affinity?: k8s.#Affinity

	// ===== Node Placement =====

	// Node selector for pod placement
	nodeSelector?: [string]: string

	// ===== Environment Variables =====

	// Additional envFrom sources to append to defaults
	// Environments specify additional sources here, not the complete list
	additionalEnvFrom: [...k8s.#EnvFromSource] | *[]

	// Additional individual env vars to append to defaults
	// Apps or environments specify additional vars here, not the complete list
	additionalEnv: [...k8s.#EnvVar] | *[]

	// ===== Volumes Configuration =====

	// Volume configuration - defines which volumes the app needs
	// If not specified, uses default volumes (data, config, cache, projected-secrets)
	volumes?: #VolumesConfig

	// Volume source names - can be overridden per environment
	volumeSourceNames?: {
		configMapName?: string
		secretName?:    string
	}

	// Cluster CA ConfigMap name - can be set at environment level
	// Used in projected volumes for TLS certificate authority configuration
	clusterCAConfigMap?: string

	// ===== Health Probes =====

	// Liveness probe configuration
	// If not specified, uses default HTTP probe on /health/live:8080
	livenessProbe?: k8s.#Probe

	// Readiness probe configuration
	// If not specified, uses default HTTP probe on /health/ready:8080
	readinessProbe?: k8s.#Probe

	// ===== Networking =====

	// Additional container ports to append to base ports
	// Base ports always include http:8080, plus debug:5005 when debug=true
	// Use this to add custom ports without replacing the defaults
	additionalContainerPorts: [...k8s.#ContainerPort] | *[]

	// Additional service ports to append to base service ports
	// Base service ports always include http:80->8080
	// Use this to add custom service ports without replacing the defaults
	additionalServicePorts: [...k8s.#ServicePort] | *[]

	// Service annotations (applied to Service metadata)
	serviceAnnotations?: [string]: string

	// ===== Debug Mode =====

	// Enable debug mode - adds debug port to deployment and creates debug service
	// Typically enabled in dev/stage environments for troubleshooting
	debug: bool | *false
}

// #VolumesConfig defines the volume configuration for an application.
// This makes volumes configurable instead of hardcoded.
#VolumesConfig: {
	// Enable standard data volume (PVC)
	enableDataVolume: bool | *true

	// Data volume PVC name (if enableDataVolume is true)
	dataVolumePVCName?: string

	// Enable standard config volume (ConfigMap)
	enableConfigVolume: bool | *true

	// Config volume ConfigMap name (if enableConfigVolume is true)
	configVolumeConfigMapName?: string

	// Enable standard cache volume (EmptyDir)
	enableCacheVolume: bool | *true

	// Cache volume settings
	cacheVolumeSettings?: {
		medium:    string | *#DefaultCacheVolumeSettings.medium
		sizeLimit: string | *#DefaultCacheVolumeSettings.sizeLimit
	}

	// Enable projected secrets volume
	enableProjectedSecretsVolume: bool | *true

	// Projected secrets configuration (if enableProjectedSecretsVolume is true)
	projectedSecretsConfig?: {
		// Secret items to project
		secretItems: [...{
			key:  string
			path: string
		}] | *#DefaultProjectedSecretItems

		// ConfigMap items to project
		configMapItems: [...{
			key:  string
			path: string
		}] | *#DefaultProjectedConfigMapItems

		// Cluster CA ConfigMap items to project
		clusterCAItems: [...{
			key:  string
			path: string
		}] | *#DefaultProjectedClusterCAItems

		// Include downward API
		includeDownwardAPI: bool | *true
	}

	// Additional custom volumes
	// Apps can specify additional volumes beyond the standard ones
	additionalVolumes?: [...k8s.#Volume]

	// Additional volume mounts
	// Apps can specify additional volume mounts beyond the standard ones
	additionalVolumeMounts?: [...k8s.#VolumeMount]
}
