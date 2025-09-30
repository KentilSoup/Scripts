name: Bug Report
description: Report a problem with a PowerShell script
title: "[Bug] <brief description>"
labels: bug
assignees: Kent-Fulton

body:
  - type: markdown
    attributes:
      value: |
        Thanks for reporting a bug! Please fill out the details below.

  - type: input
    id: script-name
    attributes:
      label: Script Name
      placeholder: e.g., Restart-WSNM.ps1

  - type: textarea
    id: description
    attributes:
      label: Bug Description
      placeholder: Describe the issue clearly.

  - type: textarea
    id: steps
    attributes:
      label: Steps to Reproduce
      placeholder: List the steps to reproduce the issue.

  - type: textarea
    id: logs
    attributes:
      label: Relevant Logs or Output
      placeholder: Paste any error messages or output here.

  - type: dropdown
    id: environment
    attributes:
      label: Environment
      options:
        - Windows 10
        - Windows 11
        - Windows Server 2019
        - Windows Server 2022
