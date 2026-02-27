Run the Rails system test suite using: PARALLEL_WORKERS=1 bundle exec rails test:system $ARGS

If $ARGS is provided, pass it directly to the test command (e.g. a file path or test name filter).
If no $ARGS, run the full system test suite.

Always use PARALLEL_WORKERS=1 to avoid pg gem segfaults with Ruby 4.0.1.
