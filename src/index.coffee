R = require 'ramda'
K = require 'kefir'
{attempt} = require 'kefir-contrib-fantasy'

# :: RetryPolicy e -> (-> Kefir e a) -> Kefir e a
#
# Retry an observable when an error is emitted, according to the retry policy.
#
# When the retry policy halts, the most recent error is emitted and the stream
# ends.
#
retrying = R.curry((policy, lazyObs) ->
  attempt(lazyObs().endOnError())
    .flatMap((either) ->
      either.fold(
        ((e) -> policy(e).fold(
          ((t) -> K.later(t._1, retrying(t._2, lazyObs)).flatMap(R.identity)),
               -> K.constantError(e))),
        K.constant)))

module.exports = retrying

