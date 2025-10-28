// Package envs provides production environment configuration
// This file contains concrete values for production instances
package envs

import (
	"example.com/cue-example/services"
)

// Import all from services to get deployment definitions
services

// Environment-level defaults shared by all apps in production
// Apps can reference these values and override them if needed
_envDefaults: {
	clusterCAConfigMap: "prod-cluster-ca"
}

// Production environment configuration for foo app
// Optimized for reliability, performance, and high availability
foo: {
	appConfig: {
		// Use specific versioned image tag for production
		// Never use 'latest' or floating tags in production
		image: "foo:v1.2.3"

		// Multiple replicas for high availability
		// Ensures service continuity during rolling updates and node failures
		replicas: 3

		// Production-grade resources
		// Sized based on actual load testing and monitoring data
		resources: {
			requests: {
				cpu:    "500m"
				memory: "1Gi"
			}
			limits: {
				cpu:    "1000m"
				memory: "2Gi"
			}
		}

		// Production namespace
		namespace: "production"

		// Node selector to run on production-grade nodes
		// Ensures production workloads run on dedicated, reliable hardware
		nodeSelector: {
			"environment": "production"
			"workload":    "application"
		}

		// Extend labels with environment-specific label
		labels: {
			environment: "production"  // Additional label for production
			tier:        "critical"     // Mark as critical tier
		}

		// Extend envFrom with production-specific shared config
		additionalEnvFrom: [
			{
				configMapRef: {
					name: "shared-production-config"
				}
			},
		]

		// Extend env with production-specific individual environment variables
		// These are only present in production
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

		// Use environment-level cluster CA ConfigMap
		clusterCAConfigMap: _envDefaults.clusterCAConfigMap

		// Debug mode disabled in production (default is false)
	}

	// Production-specific overrides for foo deployment
	deployment: {
	// Add production-specific annotations
	metadata: annotations: {
		"deployment.kubernetes.io/revision": "1"
		"maintainer":                        "platform-team@example.com"
		"cost-center":                       "engineering"
	}

	spec: {
		// More conservative rolling update for production
		strategy: rollingUpdate: {
			maxSurge:       1
			maxUnavailable: 0  // Zero downtime deployments
		}

		template: {
			// Add production-specific pod annotations
			metadata: annotations: {
				"backup.velero.io/backup-volumes": "data"
				"sidecar.istio.io/inject":          "true"  // If using service mesh
			}

			spec: {
				// Production pods get higher priority
				// priorityClassName: "production-high"

				// Spread pods across zones for high availability
				// Uncomment if your cluster has topology labels
				// affinity: podAntiAffinity: preferredDuringSchedulingIgnoredDuringExecution: [{
				// 	weight: 100
				// 	podAffinityTerm: {
				// 		labelSelector: matchLabels: {
				// 			app: "foo"
				// 		}
				// 		topologyKey: "topology.kubernetes.io/zone"
				// 	}
				// }]
			}
		}
	}
	}
}

// Production environment configuration for bar app
bar: {
	appConfig: {
		// Use specific versioned image tag for production
		image: "bar:v1.2.3"

		// Multiple replicas for high availability
		replicas: 3

		// Production-grade resources
		resources: {
			requests: {
				cpu:    "500m"
				memory: "1Gi"
			}
			limits: {
				cpu:    "1000m"
				memory: "2Gi"
			}
		}

		// Production namespace
		namespace: "production"

		// Node selector for production nodes
		nodeSelector: {
			"environment": "production"
			"workload":    "application"
		}

		// Override volume source names for production environment
		volumeSourceNames: {
			configMapName: "bar-prod-config"
			secretName:    "bar-prod-secrets"
		}

		// Use environment-level cluster CA ConfigMap
		clusterCAConfigMap: _envDefaults.clusterCAConfigMap

		// Debug mode disabled in production (default is false)
	}

	// Production-specific overrides for bar deployment
	deployment: {
		metadata: annotations: {
			"deployment.kubernetes.io/revision": "1"
			"maintainer":                        "platform-team@example.com"
			"cost-center":                       "engineering"
		}

		spec: {
			strategy: rollingUpdate: {
				maxSurge:       1
				maxUnavailable: 0
			}

			template: metadata: annotations: {
				"backup.velero.io/backup-volumes": "data"
				"sidecar.istio.io/inject":          "true"
			}
		}
	}

	// Production-specific overrides for bar ConfigMap
	configmap: {
		data: {
			// Override log level for production
			"log-level": "warn"
		}
	}
}

// Production environment configuration for baz app
baz: {
	appConfig: {
		// Use specific versioned image tag for production
		image: "baz:v1.2.3"

		// Multiple replicas for high availability
		replicas: 3

		// Production-grade resources
		resources: {
			requests: {
				cpu:    "500m"
				memory: "1Gi"
			}
			limits: {
				cpu:    "1000m"
				memory: "2Gi"
			}
		}

		// Production namespace
		namespace: "production"

		// Node selector for production nodes
		nodeSelector: {
			"environment": "production"
			"workload":    "application"
		}

		// Extend labels with environment-specific label
		labels: {
			environment: "production"
			tier:        "standard"  // Standard tier for baz
		}

		// Override volume source names for production environment
		volumeSourceNames: {
			configMapName: "baz-prod-config"
			secretName:    "baz-prod-secrets"
		}

		// Use environment-level cluster CA ConfigMap
		clusterCAConfigMap: _envDefaults.clusterCAConfigMap

		// Debug mode disabled in production (default is false)
	}

	// Production-specific overrides for baz deployment
	deployment: {
		metadata: annotations: {
			"deployment.kubernetes.io/revision": "1"
			"maintainer":                        "platform-team@example.com"
			"cost-center":                       "engineering"
		}

		spec: {
			strategy: rollingUpdate: {
				maxSurge:       1
				maxUnavailable: 0
			}

			template: metadata: annotations: {
				"backup.velero.io/backup-volumes": "data"
				"sidecar.istio.io/inject":          "true"
			}
		}
	}
}
