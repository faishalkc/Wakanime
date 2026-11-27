# Security Policy

## Scope

Wakanime is an offline-first Android application with local SQLite storage, local image file handling, and a manual HTTP import mechanism (Tenrai API). Relevant security concerns include, but are not limited to:

- Unsafe local file path handling or unintended filesystem access when saving, replacing, or deleting poster images.
- SQLite query or data-integrity vulnerabilities (for example, unparameterized SQL queries).
- Security issues in handling remote responses or image downloads during manual API import.
- Dependency vulnerabilities that affect the Android application.

## Reporting a Vulnerability

Please **do not** disclose potential security vulnerabilities in public issues, pull requests, or discussions before they have been reviewed.

If the repository hosting platform provides a private vulnerability reporting feature (such as GitHub Security Advisories), please submit your report there. Otherwise, reach out to the repository maintainer privately through the contact options available on the hosting platform.

## What to Include in a Report

To help evaluate and reproduce the issue, please provide:

- A clear description of the vulnerability and its potential impact.
- Step-by-step instructions or a minimal reproduction case.
- The affected files, screens, or components (if known).
- Any relevant error logs or environment details (Android version, Flutter version).

## Handling Reports

Reports will be reviewed by the maintainer to confirm the issue and determine an appropriate fix. Please allow reasonable time for investigation and remediation before sharing details publicly.
