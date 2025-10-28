// Package envs provides development environment configuration
// This file contains concrete values for development instances
package envs

import (
	"example.com/cue-example/services"
)

// Import all from services to get deployment definitions
services

// Environment-level defaults shared by all apps in development
// Apps can reference these values and override them if needed
_envDefaults: {
	clusterCAConfigMap: "dev-cluster-ca"
}

// Development environment configuration for foo app
// Optimized for fast iteration and minimal resource usage
foo: appConfig: {
	// Use latest dev image for rapid iteration
	image: "foo:dev-latest"

	// Single replica for development
	replicas: 1

	// Minimal resources for development
	// Suitable for local clusters (minikube, kind) or shared dev clusters
	resources: {
		requests: {
			cpu:    "100m"
			memory: "128Mi"
		}
		limits: {
			cpu:    "200m"
			memory: "256Mi"
		}
	}

	// Development namespace
	namespace: "dev"

	// No node selector - can run on any node
	// nodeSelector not specified, runs anywhere

	// Use environment-level cluster CA ConfigMap
	clusterCAConfigMap: _envDefaults.clusterCAConfigMap

	// Enable debug mode for development troubleshooting
	// Automatically adds debug port (5005) and creates separate debug service
	debug: true
}

// Development environment configuration for bar app
// Optimized for fast iteration and minimal resource usage
bar: appConfig: {
	// Use latest dev image for rapid iteration
	image: "bar:dev-latest"

	// Single replica for development
	replicas: 1

	// Minimal resources for development
	resources: {
		requests: {
			cpu:    "100m"
			memory: "128Mi"
		}
		limits: {
			cpu:    "200m"
			memory: "256Mi"
		}
	}

	// Development namespace
	namespace: "dev"

	// Override environment default with app-specific cluster CA ConfigMap
	// Demonstrates per-app override capability
	clusterCAConfigMap: "bar-custom-dev-ca"

	// Debug mode disabled for bar (default is false)
}

// Development environment configuration for baz app
// Optimized for fast iteration and minimal resource usage
baz: appConfig: {
	// Use latest dev image for rapid iteration
	image: "baz:dev-latest"

	// Single replica for development
	replicas: 1

	// Minimal resources for development
	resources: {
		requests: {
			cpu:    "100m"
			memory: "128Mi"
		}
		limits: {
			cpu:    "200m"
			memory: "256Mi"
		}
	}

	// Development namespace
	namespace: "dev"

	// Use environment-level cluster CA ConfigMap
	clusterCAConfigMap: _envDefaults.clusterCAConfigMap

	// Debug mode disabled for baz (default is false)
}
