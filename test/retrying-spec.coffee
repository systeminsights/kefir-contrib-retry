K = require 'kefir'
R = require 'ramda'
{Left, Right} = require 'fantasy-eithers'
{runLog} = require 'kefir-contrib-run'
policy = require 'retry-policy'
retrying = require '../src/index'

lazyStreams = (ss) ->
  ss0 = ss
  streams0 = ->
    s = R.head(ss0)
    ss0 = R.tail(ss0) if ss0.length > 1
    s
  streams0

describe "retrying", ->
  it "should retry stream on error, until the policy halts", ->
    pol = policy.both(policy.limit(1), policy.constant(500))
    s = lazyStreams([
      K.sequentially(50, [1, 2, 3]).concat(K.constantError("E1")),
      K.constant(5).concat(K.constantError("E2"))
    ])
    expect(runLog(retrying(pol, s))).to.become([Right(1), Right(2), Right(3), Right(5), Left("E2")])

  it "should end on error when first retry function never retries", ->
    s = -> K.sequentially(50, [4, 5, 6]).concat(K.constantError("E"))
    expect(runLog(retrying(policy.halt, s))).to.become([Right(4), Right(5), Right(6), Left("E")])

  it "should not affect the stream when no errors emitted", ->
    pol = policy.constant(500)
    expect(runLog(retrying(pol, -> K.sequentially(50, [1, 2, 3])))).to.become([Right(1), Right(2), Right(3)])

