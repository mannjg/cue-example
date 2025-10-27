// Package services defines the application-specific configuration for bar
// This file instantiates the shared application template with bar-specific settings
package services

import "example.com/cue-example/k8s"

// bar application configuration
// Uses the #AppBase template from base.cue with bar-specific customizations
bar: #AppBase & {
	// Set the application name
	appName: "bar"

	// Use default namespace pattern: "bar-namespace"
	// Can be overridden by environments via appConfig.namespace

	// Resources exported for this app: deployment, service, and configmap
	// Bar includes a ConfigMap resource in addition to the defaults
	resources_list: ["deployment", "service", "configmap"]
}

// Add ConfigMap resource for bar
// Defined separately to allow proper scoping of appConfig reference
bar: configmap: k8s.#ConfigMap & {
	metadata: {
		name:      "bar-config"
		namespace: bar.appConfig.namespace
		labels:    bar.appConfig.labels
	}

	data: {
		"redis-url": string | *"redis://redis.cache.svc.cluster.local:6379"
		"log-level": string | *"info"
	}
}
