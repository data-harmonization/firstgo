Feature: templates
  A template can be used as a base when sending a message

  Scenario: Empty list of templates
    Given User1 gets /myservice/v1/template
    Then the response code should be 200
