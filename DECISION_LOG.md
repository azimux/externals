This document is intended to document the rationale behind certain key decisions

# 2026-07-23 Use # :nocov: to artificially get to 100% coverage

## Problem

It's problematic to have a coverage enforcement number for any coverage percent other than 100%.

This is because then doing things like deleting a line that was covered will lower coverage and fail the build.

## Decision

Let's apply a hack I heard from somebody: just # :nocov: uncovered stuff and set the limit to 100%.

All of these are marked by the comment `# TODO: test (or delete) this code path!`

Then, turn on 100% line coverage enforcement in the test suite.

Going forward, all changes/additions should have tests. This is not a decision to # :nocov: future
features/changes.

## Rationale

Another option is to just legitimately write tests to get to 100%.

This is not a priority for me at the moment and I'm more eager to get this project alive again
and put it to direct use.

I would like to "modernize" it, though, in the sense of adding at least 100% line coverage
(I would prefer branch coverage.)

## Concerns

This, of course, increases the chances that I'll never test these paths.
