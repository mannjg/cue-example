// Package envs provides production environment configuration
// This file contains concrete values for production instances
package envs

import (
	apps "example.com/cue-example/services/apps"
	base "example.com/cue-example/services/base"
)

// Bring service definitions into this package with explicit references
foo: apps.foo
bar: apps.bar
baz: apps.baz

// Environment-level defaults shared by all apps in production
// Apps can reference these values and override them if needed
_envDefaults: {
	clusterCAConfigMap: "prod-cluster-ca"
	namespace:          "production"
	replicas:           3

	// Enable HTTPS for all apps in production
	enableHttps: true

	// Production-grade resources
	resources: base.#DefaultProductionResources

	// Node selector for production nodes
	nodeSelector: {
		"environment": "production"
		"workload":    "application"
	}

	// Production-specific labels
	labels: base.#DefaultProductionLabels

	// Production-specific envFrom
	additionalEnvFrom: [
		{
			configMapRef: {
				name: "shared-production-config"
			}
		},
	]

	// More conservative rolling update strategy for production
	deploymentStrategy: base.#DefaultProductionDeploymentStrategy
}

// Production environment configuration for foo app
// Optimized for reliability, performance, and high availability
foo: appConfig: {
	// Use specific versioned image tag for production
	// Never use 'latest' or floating tags in production
	image: "foo:v1.2.3"

	// Use environment-level defaults for common production settings
	_envDefaults

	// Foo-specific production environment variables
	additionalEnv: [
		{
			name:  "PRODUCTION_MODE"
			value: "true"
		},
		{
			name:  "ALERT_WEBHOOK_URL"
			value: "https://alerts.example.com/webhook/foo"
		},
	]

	// Override volume source names for production environment
	volumeSourceNames: {
		configMapName: "foo-prod-config"
		secretName:    "foo-prod-secrets"
	}

	// Production-specific deployment annotations
	deploymentAnnotations: {
		"deployment.kubernetes.io/revision": "1"
		"maintainer":                        "platform-team@example.com"
		"cost-center":                       "engineering"
	}

	// Production-specific pod annotations
	podAnnotations: {
		"backup.velero.io/backup-volumes": "data"
		"sidecar.istio.io/inject":          "true"  // If using service mesh
	}

	// Uncomment to enable production pod priority and anti-affinity
	// priorityClassName: "production-high"
	// affinity: {
	// 	podAntiAffinity: preferredDuringSchedulingIgnoredDuringExecution: [{
	// 		weight: 100
	// 		podAffinityTerm: {
	// 			labelSelector: matchLabels: app: "foo"
	// 			topologyKey: "topology.kubernetes.io/zone"
	// 		}
	// 	}]
	// }
}

// Production environment configuration for bar app
bar: {
	appConfig: {
		// Use specific versioned image tag for production
		image: "bar:v1.2.3"

		// Use environment-level defaults for common production settings
		_envDefaults

		// Override volume source names for production environment
		volumeSourceNames: {
			configMapName: "bar-prod-config"
			secretName:    "bar-prod-secrets"
		}

		// Production-specific deployment annotations
		deploymentAnnotations: {
			"deployment.kubernetes.io/revision": "1"
			"maintainer":                        "platform-team@example.com"
			"cost-center":                       "engineering"
		}

		// Production-specific pod annotations
		podAnnotations: {
			"backup.velero.io/backup-volumes": "data"
			"sidecar.istio.io/inject":          "true"
		}

		// Debug mode disabled in production (default is false)
	}

	// Provide ConfigMap metadata and data overrides
	resources: configmap: {
		metadata: {
			namespace: "production"
			labels: {
				app:        "bar"
				deployment: "bar"
			}
		}

		// Override log level for production
		data: "log-level": "warn"
	}
}

// Production environment configuration for baz app
baz: appConfig: {
	// Use specific versioned image tag for production
	image: "baz:v1.2.3"

	// Use environment-level defaults for most settings
	clusterCAConfigMap:   _envDefaults.clusterCAConfigMap
	namespace:            _envDefaults.namespace
	replicas:             _envDefaults.replicas
	enableHttps:          _envDefaults.enableHttps
	resources:            _envDefaults.resources
	nodeSelector:         _envDefaults.nodeSelector
	additionalEnvFrom:    _envDefaults.additionalEnvFrom
	deploymentStrategy:   _envDefaults.deploymentStrategy

	// Override tier label for baz (standard instead of critical)
	labels: {
		environment: "production"
		tier:        "standard"  // Override from critical to standard
	}

	// Override volume source names for production environment
	volumeSourceNames: {
		configMapName: "baz-prod-config"
		secretName:    "baz-prod-secrets"
	}

	// Production-specific deployment annotations
	deploymentAnnotations: {
		"deployment.kubernetes.io/revision": "1"
		"maintainer":                        "platform-team@example.com"
		"cost-center":                       "engineering"
	}

	// Production-specific pod annotations
	podAnnotations: {
		"backup.velero.io/backup-volumes": "data"
		"sidecar.istio.io/inject":          "true"
	}

	// Debug mode disabled in production (default is false)
}
