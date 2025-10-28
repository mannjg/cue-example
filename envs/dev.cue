// Package envs provides development environment configuration
// This file contains concrete values for development instances
package envs

import (
	svc "example.com/cue-example/services"
)

// Bring service definitions into this package with explicit references
// This makes the configuration flow clearer and more maintainable
foo: svc.foo
bar: svc.bar
baz: svc.baz

// Environment-level defaults shared by all apps in development
// Apps can reference these values and override them if needed
_envDefaults: {
	clusterCAConfigMap: "dev-cluster-ca"
	namespace:          "dev"

	// Common development resource limits
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
}

// Development environment configuration for foo app
// Optimized for fast iteration and minimal resource usage
foo: appConfig: {
	// Use latest dev image for rapid iteration
	image: "foo:dev-latest"

	// Single replica for development
	replicas: 1

	// Use environment-level defaults for common settings
	_envDefaults

	// Enable debug mode for development troubleshooting
	// Automatically adds debug port (5005) and creates separate debug service
	debug: true
}

// Development environment configuration for bar app
// Optimized for fast iteration and minimal resource usage
bar: {
	appConfig: {
		// Use latest dev image for rapid iteration
		image: "bar:dev-latest"

		// Single replica for development
		replicas: 1

		// Use environment-level defaults except clusterCAConfigMap
		namespace: _envDefaults.namespace
		resources:  _envDefaults.resources

		// Override environment default with app-specific cluster CA ConfigMap
		// Demonstrates per-app override capability
		clusterCAConfigMap: "bar-custom-dev-ca"

		// Debug mode disabled for bar (default is false)
	}

	// Provide ConfigMap metadata
	configmap: metadata: {
		namespace: "dev"
		labels: {
			app:        "bar"
			deployment: "bar"
		}
	}
}

// Development environment configuration for baz app
// Optimized for fast iteration and minimal resource usage
baz: appConfig: {
	// Use latest dev image for rapid iteration
	image: "baz:dev-latest"

	// Single replica for development
	replicas: 1

	// Use environment-level defaults for common settings
	_envDefaults

	// Debug mode disabled for baz (default is false)
}
