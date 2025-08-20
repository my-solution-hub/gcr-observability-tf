# CI - AWS CodeBuild with GitLab

## BuildSpec Requirements

Need buildspec to run different actions based on branch merge:

- **Source**: GitLab repository
- **Trigger**: Branch-based builds
- **Actions**: Different build steps per branch type

## Branch Strategy

- `main` branch: Full deployment pipeline
- `develop` branch: Testing and validation
- `feature/*` branches: Code validation only

## TODO

- [ ] Create buildspec.yml with conditional logic
- [ ] Configure GitLab webhook integration
- [ ] Set up branch-specific build actions
