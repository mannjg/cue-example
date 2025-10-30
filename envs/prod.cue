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
	namespace: "production"

	// Enable HTTPS for all apps in production
	enableHttps: true

	// Production-specific labels
	labels: base.#DefaultProductionLabels

	deployment: {
		clusterCAConfigMap: "prod-cluster-ca"
		replicas:           3

		// Production-grade resources
		resources: base.#DefaultProductionResources

		// Node selector for production nodes
		nodeSelector: {
			"environment": "production"
			"workload":    "application"
		}

		// Production-specific envFrom
		additionalEnvFrom: [
			{
				configMapRef: {
					name: "shared-production-config"
				}
			},
		]

		// More conservative rolling update strategy for production
		strategy: base.#DefaultProductionDeploymentStrategy
	}
}

// Production environment configuration for foo app
// Optimized for reliability, performance, and high availability
foo: {
	// Setup renderer with production-specific input values
	// Note: Cache disabled in production to demonstrate conditional logic
	_renderer: apps.#FooRenderer & {
		inputs: {
			// Scalar inputs for transformation
			apiKey:      "prod-api-key-secure-xyz789"
			dbUrl:       "postgres://prod-db.example.com:5432/foo_prod"
			enableCache: false  // Disabled in prod to demonstrate conditional logic
			logLevel:    "warn"
			maxRetries:  10

			// Pass complete appConfig as input to renderer
			appConfig: {
				// Use environment-level defaults for common production settings
				_envDefaults

				deployment: {
					// Use specific versioned image tag for production
					// Never use 'latest' or floating tags in production
					image: "foo:v1.2.3"

					// Production environment variables
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
					annotations: {
						"deployment.kubernetes.io/revision": "1"
						"maintainer":                        "platform-team@example.com"
						"cost-center":                       "engineering"
					}

					// Production-specific pod annotations
					podAnnotations: {
						"backup.velero.io/backup-volumes": "data"
						"sidecar.istio.io/inject":          "true" // If using service mesh
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
			}
		}
	}

	// Use rendered config directly - no additional merging needed!
	appConfig: _renderer.renderedConfig
}

// Production environment configuration for bar app
bar: {
	appConfig: {
		// Use environment-level defaults for common production settings
		_envDefaults

		// Debug mode disabled in production (default is false)

		deployment: {
			// Use specific versioned image tag for production
			image: "bar:v1.2.3"

			// Override volume source names for production environment
			volumeSourceNames: {
				configMapName: "bar-prod-config"
				secretName:    "bar-prod-secrets"
			}

			// Production-specific deployment annotations
			annotations: {
				"deployment.kubernetes.io/revision": "1"
				"maintainer":                        "platform-team@example.com"
				"cost-center":                       "engineering"
			}

			// Production-specific pod annotations
			podAnnotations: {
				"backup.velero.io/backup-volumes": "data"
				"sidecar.istio.io/inject":          "true"
			}
		}

		// Override log level for production
		configMap: data: "log-level": "warn"
	}
}

// Production environment configuration for baz app
baz: appConfig: {
	// Use environment-level defaults for most settings
	namespace:   _envDefaults.namespace
	enableHttps: _envDefaults.enableHttps

	// Override tier label for baz (standard instead of critical)
	labels: {
		environment: "production"
		tier:        "standard" // Override from critical to standard
	}

	deployment: {
		// Use specific versioned image tag for production
		image: "baz:v1.2.3"

		// Use environment-level deployment defaults
		clusterCAConfigMap: _envDefaults.deployment.clusterCAConfigMap
		replicas:           _envDefaults.deployment.replicas
		resources:          _envDefaults.deployment.resources
		nodeSelector:       _envDefaults.deployment.nodeSelector
		additionalEnvFrom:  _envDefaults.deployment.additionalEnvFrom
		strategy:           _envDefaults.deployment.strategy

		// Override volume source names for production environment
		volumeSourceNames: {
			configMapName: "baz-prod-config"
			secretName:    "baz-prod-secrets"
		}

		// Production-specific deployment annotations
		annotations: {
			"deployment.kubernetes.io/revision": "1"
			"maintainer":                        "platform-team@example.com"
			"cost-center":                       "engineering"
		}

		// Production-specific pod annotations
		podAnnotations: {
			"backup.velero.io/backup-volumes": "data"
			"sidecar.istio.io/inject":          "true"
		}
	}

	// Debug mode disabled in production (default is false)
}
