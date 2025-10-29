// Package services provides shared application templates and patterns
// This file defines the ConfigMap resource template
package resources

import (
	"example.com/cue-example/k8s"
	base "example.com/cue-example/services/base"
)

// #ConfigMapTemplate generates a Kubernetes ConfigMap when configMapData is provided.
// This template creates an app-specific ConfigMap that can be mounted into the deployment.
#ConfigMapTemplate: {
	// Required inputs
	appName:   string
	appConfig: base.#AppConfig

	// Default labels (can be extended via appConfig.labels)
	_defaultLabels: {
		app:        appName
		deployment: appName
	}

	// Computed labels - merge defaults with config
	_labels: _defaultLabels & appConfig.labels

	// The ConfigMap resource (only created if configMapData is provided)
	if appConfig.configMapData != _|_ {
		configmap: k8s.#ConfigMap & {
			metadata: {
				name:      "\(appName)-config"
				namespace: appConfig.namespace
				labels:    _labels
			}

			data: appConfig.configMapData.data
		}
	}
}
