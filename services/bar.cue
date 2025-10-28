// Package services defines the application-specific configuration for bar
// This file instantiates the shared application template with bar-specific settings
package services

import "example.com/cue-example/k8s"

// bar application configuration
// Uses the #App template with bar-specific customizations
bar: #App & {
	// Set the application name
	appName: "bar"

	// Bar includes a ConfigMap resource in addition to the standard resources
	// Override resources_list to include it
	resources_list: ["deployment", "service", "configmap"]

	// Add ConfigMap resource for bar
	// This demonstrates how apps can extend the base template with additional resources
	// Note: Environment files must provide metadata.namespace and metadata.labels via overrides
	configmap: k8s.#ConfigMap & {
		metadata: {
			name: "bar-config"
			// namespace and labels must be provided by environment files
		}

		data: {
			"redis-url": string | *"redis://redis.cache.svc.cluster.local:6379"
			"log-level": string | *"info"
		}
	}
}
