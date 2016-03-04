module.exports = (grunt) ->

  grunt.initConfig
    pkg: grunt.file.readJSON("package.json")

    clean:
      build: ["build"]
      dist: ["dist"]
      test: ["coverage", "coverage-lcov"]
      testjs: ["tests/*js"]
      shrinkwrap: ["npm-shrinkwrap.*"]

    coveralls:
      options:
        debug: true
        coverageDir: 'coverage-lcov'
        dryRun: false
        force: true
        recursive: true

    concat:
      options:
        separator: ";"

      mywallet:
        src: [
          'build/blockchain.js'
        ]
        dest: "dist/my-wallet.js"

    replace:
      # monkey patch deps
      bitcoinjs:
        # comment out value validation in fromBuffer to speed up node
        # creation from cached xpub/xpriv values
        src: ['node_modules/bitcoinjs-lib/src/hdnode.js'],
        overwrite: true,
        replacements: [{
          from: /\n    curve\.validate\(Q\)/g
          to:   '\n    // curve.validate(Q)'
        }]

    uglify:
      options:
        banner: "/*! <%= pkg.name %> <%= grunt.template.today(\"yyyy-mm-dd\") %> */\n"
        mangle: false

      mywallet:
        src:  "dist/my-wallet.js"
        dest: "dist/my-wallet.min.js"

    browserify:
      options:
        debug: true
        browserifyOptions: { standalone: "Blockchain" }

      build:
        src: ['index.js']
        dest: 'build/blockchain.js'

      production:
        options:
          debug: false
        src: '<%= browserify.build.src %>'
        dest: 'build/blockchain.js'

    # TODO should auto-run and work on all files
    jshint:
      files: [
        #'src/blockchain-api.js'
        'src/blockchain-settings-api.js'
        'src/hd-account.js'
        'src/hd-wallet.js'
        'src/import-export.js'
        #'src/shared.js'
        #'src/sharedcoin.js'
        'src/transaction.js'
        'src/wallet-signup.js'
        'src/payment.js'
        #'src/wallet.js'
      ]
      options:
        globals:
          jQuery: true

    watch:
      scripts:
        files: [
          'src/**/*.js'
        ]
        tasks: ['build']

    shell:
      check_dependencies:
        command: () ->
           'mkdir -p build && ruby check-dependencies.rb'

      skip_check_dependencies:
        command: () ->
          'cp -r node_modules build'

      npm_install_dependencies:
        command: () ->
           'cd build && npm install'

      tag:
        command: (newVersion, message) ->
          'git tag -a -s ' + newVersion + " -m " + message + ' && git push --tags'

      pull_bower_repo:
        command: () ->
          'cd ../My-Wallet-V3-Bower && git pull'

      copy_changelog:
        command: () ->
          'cp Changelog.md ../My-Wallet-V3-Bower'

      mv_shrinkwrap:
        command: () ->
          'mv npm-shrinkwrap.json ../My-Wallet-V3-Bower'

      copy_dist:
        command: () ->
          'cp dist/my-wallet.* ../My-Wallet-V3-Bower/dist'

      bower_version:
        command: (version) ->
          [
           "cd ../My-Wallet-V3-Bower"
           "git add Changelog.md npm-shrinkwrap.json"
           "git commit -m 'Changelog and NPM shrinkwrap for #{ version }'"
           "bower version #{ version }"
          ].join(" && ")

      push_bower:
        command: () ->
          'cd ../My-Wallet-V3-Bower && git push && git push --tags'

      sign_bower_tag:
        command: (newVersion) ->
          "cd ../My-Wallet-V3-Bower && git tag #{ newVersion } #{ newVersion } -f -a -s -m '#{ newVersion }'"

      untag:
        command: (tag) ->
          'git tag -d ' + tag + ' && git push origin :refs/tags/' + tag + ' && cd ../My-Wallet-V3-Bower && git tag -d ' + tag + ' && git push origin :refs/tags/' + tag

      test_once:
        command: () ->
          './node_modules/karma/bin/karma start karma.conf.js --single-run'

      shrinkwrap:
        command: () ->
          'npm shrinkwrap'

      shrinkwrap_dev:
        command: () ->
          # This causes the dependency check to fail currently:
          'npm shrinkwrap --dev'

    env:
      build:
        DEBUG: "1"
        PRODUCTION: "0"

      production:
        PRODUCTION: "1"

    preprocess:
      js:
        expand: true
        cwd: 'src/'
        src: '**/*.js'
        dest: 'build'
        ext: '.processed.js'

    git_changelog:
      default:
        options:
          file: 'Changelog.md',
          app_name : 'Blockchain Wallet V3',
          intro : 'Recent changes'
          grep_commits: '^fix|^feat|^docs|^refactor|^chore|^test|BREAKING'
          repo_url: 'https://github.com/blockchain/My-Wallet-V3'

    semistandard:
      app:
        src:
          ['{,src/}*.js']

  grunt.loadNpmTasks 'grunt-browserify'
  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-contrib-concat'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-env'
  grunt.loadNpmTasks 'grunt-contrib-jshint'
  grunt.loadNpmTasks 'grunt-preprocess'
  grunt.loadNpmTasks 'grunt-shell'
  grunt.loadNpmTasks 'grunt-text-replace'
  grunt.loadNpmTasks 'git-changelog'
  grunt.loadNpmTasks 'grunt-karma-coveralls'
  grunt.loadNpmTasks 'grunt-semistandard'

  grunt.registerTask "default", [
    "build"
    "watch"
  ]

  grunt.registerTask "build", [
    "env:build"
    "preprocess"
    "replace:bitcoinjs"
    "browserify:build"
    "concat:mywallet"
  ]

  # Skip dependency check, e.g. for staging:
  grunt.registerTask "dist_unsafe", [
    "env:production"
    "clean:build"
    "clean:dist"
    "shell:skip_check_dependencies"
    "preprocess"
    "replace:bitcoinjs"
    "browserify:production"
    "concat:mywallet"
    "uglify:mywallet"
  ]

  # E.g. when shipping 3.0.1:
  # grunt bower:3.0.1:"New stuff"
  # Expects ../My-Wallet-V3-Bower to exist
  grunt.registerTask "bower", "bower(version)", (newVersion) =>
    if newVersion == undefined || newVersion[0] != "v"
      grunt.fail.fatal("Missing version or version is missing 'v'")

    grunt.task.run [
      "clean"
      "shell:pull_bower_repo"
      "build"
      "shell:test_once"
      "env:production"
      "shell:shrinkwrap"
      "shell:check_dependencies"
      "shell:npm_install_dependencies"
      "preprocess"
      "replace:bitcoinjs"
      "browserify:production"
      "concat:mywallet"
      "uglify:mywallet"
      "git_changelog"
      "shell:tag:#{ newVersion }:#{ newVersion }"
      "shell:copy_changelog"
      "shell:shrinkwrap_dev"
      "shell:mv_shrinkwrap"
      "shell:copy_dist"
      "shell:bower_version:#{ newVersion }"
      "shell:sign_bower_tag:#{ newVersion }"
      "shell:push_bower"
      "release_done:#{ newVersion }"
    ]

  grunt.registerTask "release_done", (version) =>
    console.log "Release done. Please copy Changelog.md over to Github release notes:"
    console.log "https://github.com/blockchain/My-Wallet-V3/releases/edit/#{ version }"

  grunt.registerTask "untag", "remove tag", (tag) =>
    grunt.task.run [
      "shell:untag:" + tag
    ]

  return
