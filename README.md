Heroku Buildpack for Node.js
============================

> **Note (October 2026):** this fork (2014) adds a JDK to the Node.js buildpack, so that a Node.js application can run Java programs. It is kept for the record.
>
> It was fixed in 2026. The JDK is now installed by running Heroku's JVM buildpack (release v187, checksum-verified) as a sub-buildpack, instead of sourcing the 2014 JVM library into the application's build directory, and its version comes from `java.runtime.version` in `system.properties`. Node versions are resolved against nodejs.org's release index instead of semver.io, which is gone, and node is downloaded from nodejs.org and checked against the release's SHA-256 sums instead of Heroku's retired S3 mirror. The rest is the 2014 buildpack, and it has not been tested on a current Heroku stack.
>
> Today the same thing takes no fork. Put `java.runtime.version=21` (or the version you need) in `system.properties`, and add the JVM buildpack in front of the Node.js one:
>
>     heroku buildpacks:set heroku/nodejs
>     heroku buildpacks:add --index 1 heroku/jvm
>
> The story of this fork: [Blast from the past: the Heroku buildpacks I forked](https://bkarak.wizhut.tech/blog/2026/29102026).

This is the official [Heroku buildpack](http://devcenter.heroku.com/articles/buildpacks) for Node.js apps. If you fork this repository, please **update this README** to explain what your fork does and why it's special.


How it Works
------------

Here's an overview of what this buildpack does:

- Uses [nodejs.org's release index](https://nodejs.org/dist/index.json) to find the newest version of node that satisfies the [engines.node semver range](https://docs.npmjs.com/cli/configuring-npm/package-json#engines) in your package.json (exact versions, x-ranges, `^` and `~`; anything else gets the latest LTS release).
- Allows any version of node published on nodejs.org to be used.
- Downloads the node binary from nodejs.org and checks it against the SHA-256 sums published with the release.
- Installs a JDK with Heroku's [JVM buildpack](https://github.com/heroku/heroku-buildpack-jvm-common), using `java.runtime.version` from `system.properties`, and puts `java` on the `PATH`.
- Discourages use of dangerous semver ranges like `*` and `>0.10`.
- Uses the version of `npm` that comes bundled with `node`.
- Puts `node` and `npm` on the `PATH` so they can be executed with [heroku run](https://devcenter.heroku.com/articles/one-off-dynos#an-example-one-off-dyno).
- Caches the `node_modules` directory across builds for fast deploys.
- Doesn't use the cache if `node_modules` is checked into version control.
- Runs `npm rebuild` if `node_modules` is checked into version control.
- Always runs `npm install` to ensure [npm script hooks](https://npmjs.org/doc/misc/npm-scripts.html) are executed.
- Always runs `npm prune` after restoring cached modules to ensure cleanup of unused dependencies.

For more technical details, see the [heavily-commented compile script](https://github.com/heroku/heroku-buildpack-nodejs/blob/master/bin/compile).


Documentation
-------------

For more information about using Node.js and buildpacks on Heroku, see these Dev Center articles:

- [Heroku Node.js Support](https://devcenter.heroku.com/articles/nodejs-support)
- [Getting Started with Node.js on Heroku](https://devcenter.heroku.com/articles/nodejs)
- [10 Habits of a Happy Node Hacker](https://blog.heroku.com/archives/2014/3/11/node-habits)
- [Buildpacks](https://devcenter.heroku.com/articles/buildpacks)
- [Buildpack API](https://devcenter.heroku.com/articles/buildpack-api)


Legacy Compatibility
--------------------

For most Node.js apps this buildpack should work just fine. If, however, you're unable to deploy using this new version of the buildpack, you can get your app working again by using the legacy branch:

```
heroku config:set BUILDPACK_URL=https://github.com/heroku/heroku-buildpack-nodejs#legacy -a my-app
git commit -am "empty" --allow-empty # force a git commit
git push heroku master
```

Then please open a support ticket at [help.heroku.com](https://help.heroku.com/) so we can diagnose and get your app running on the default buildpack.

Hacking
-------

To make changes to this buildpack, fork it on Github. Push up changes to your fork, then create a new Heroku app to test it, or configure an existing app to use your buildpack:

```
# Create a new Heroku app that uses your buildpack
heroku create --buildpack <your-github-url>

# Configure an existing Heroku app to use your buildpack
heroku config:set BUILDPACK_URL=<your-github-url>

# You can also use a git branch!
heroku config:set BUILDPACK_URL=<your-github-url>#your-branch
```


Testing
-------

[Anvil](https://github.com/ddollar/anvil) is a generic build server for Heroku.

```
gem install anvil-cli
```

The [heroku-anvil CLI plugin](https://github.com/ddollar/heroku-anvil) is a wrapper for anvil.

```
heroku plugins:install https://github.com/ddollar/heroku-anvil
```

The [ddollar/test](https://github.com/ddollar/buildpack-test) buildpack runs `bin/test` on your app/buildpack.

```
heroku build -b ddollar/test # -b can also point to a local directory
```

For more info on testing, see [Best Practices for Testing Buildpacks](https://discussion.heroku.com/t/best-practices-for-testing-buildpacks/294) on the Heroku discussion forum.
