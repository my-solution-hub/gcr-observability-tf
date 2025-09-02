package com.example.hello.controller;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Controller
public class IndexController {

    private static final Logger logger = LoggerFactory.getLogger(IndexController.class);

    @GetMapping("/")
    public String home(Model model) {
        logger.info("Home page requested");
        
        // Add dynamic resource attributes from environment
        model.addAttribute("serviceVersion", System.getenv().getOrDefault("SERVICE_VERSION", "1.0.0"));
        model.addAttribute("deploymentEnvironment", System.getenv().getOrDefault("DEPLOYMENT_ENVIRONMENT", "dev"));
        model.addAttribute("k8sClusterName", System.getenv().getOrDefault("K8S_CLUSTER_NAME", "unknown"));
        model.addAttribute("k8sNamespaceName", System.getenv().getOrDefault("K8S_NAMESPACE_NAME", "default"));
        
        return "index";
    }
}
