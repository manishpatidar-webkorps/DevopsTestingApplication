package org.clone.devopsapplicationtesting.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class TestController {

    @GetMapping("/testing")
public String testApplication(){
    return "Application is working fine";
}


}
