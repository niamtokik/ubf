
This is ubf, a framework for Getting Erlang to talk to the outside
world.  This repository is based on Joe Armstrong's original UBF code
with an MIT license file added to the distribution.


To build
========

1. Get and install an erlang system
   http://www.erlang.org

2. Change to the src directory and type make
   $ cd src
   $ make

3. Run the unit test
   $ make check


Documentation -- Where should I start?
======================================

This README is a good first step.  Check out and build using the "To
build" instructions above.

The documentation is in a state of slow improvement.  Contributions
from the wider world are welcome.  :-)

One of the better places to start is to look in the "edoc" directory.
See the "Reference Documentation" section for suggestions on where to
find greater detail.

The unit tests in the "src/Unit-Test-Files" directory provide small
examples of how to use all of the public API.  In particular, the
*client*.erl files contain comments at the top with a list of
prerequisites and small examples, recipe-style, for starting each
server and using the client.

The eunit tests in the "src/Unit-EUnit-Files" directory perform
several smoke and error handling uses cases.

The original documentation is in the "priv/doc" directory.

The #1 most frequently asked question is: "My term X fails contract
Y, but I can't figure out why!  This X is perfectly OK.  What is going
on?"  See the the EDoc documentation for the contracts:checkType/3
function.


What is UBF?
============

UBF is the "Universal Binary Format", designed and implemented by Joe
Armstrong.  See http://www.sics.se/~joe/ubf.html for full details.  A
really short summary:

   * UBF(A) is a protocol above a stream transport (e.g. TCP/IP), for
     encoding structured data roughly equivalent to well-formed XML.

   * UBF(B) is a programming langauge for describing types in UBF(A)
     and protocols between clients and servers. UBF(B) is roughly
     equivalent to to Verified XML, XML-schemas, SOAP and WDSL.

   * UBF(C) is a meta-level protocol used between a UBF client and a
     UBF server.


What is EBF?
============

EBF is an implementation of UBF(B) but does not use UBF(A) for
client<->server communication.  Instead, Erlang-style conventions are
used instead:

   * Structured terms are serialized via the Erlang BIFs
     term_to_binary() and binary_to_term().

   * Terms are framed using the 'gen_tcp' {packet, 4} format: a 32-bit
     unsigned integer (big-endian?) specifies packet length.

     +-------------------------+-------------------------------+
     | Packet length (32 bits) | Packet data (variable length) |
     +-------------------------+-------------------------------+

The name "EBF" is short for "Erlang Binary Format".



What about JSF and JSON-RPC?
============================

See the ubf-jsonrpc open source repository
http://github.com/norton/ubf-jsonrpc for details.  ubf-jsonrpc is a
framework for integrating UBF, JSF, and JSON-RPC.


What about TBF and Thrift?
==========================

See the ubf-thrift open source repository
http://github.com/norton/ubf-thrift for details.  ubf-thrift is a
framework for integrating UBF, TBF, and Thrift.


What about ABNF?
================

See the ubf-abnf open source repository
http://github.com/norton/ubf-abnf for details.  ubf-abnf is a
framework for integrating UBF and ABNF.


What about EEP8?
================

See the ubf-eep8 open source repository
http://github.com/norton/ubf-eep8 for details.  ubf-eep8 is a
framework for integrating UBF and EEP8.


To do (in short term)
=====================

  - cleanup (or remove) old documentation under priv/doc
  - document new features
    + predefined ubf contract (and contract checker) primitives
      - atom(), binary(), float(), integer(), list(), proplist(),
        string(), term(), tuple(), void()
      - atom(ascii), atom(asciiprintable), atom(nonempty), atom(nonundefined),
        atom(ascii,nonempty), atom(ascii,nonundefined),
        atom(asciiprintable,nonempty), atom(asciiprintable,nonundefined),
        atom(ascii,nonempty,nonundefined),
        atom(asciiprintable,nonempty,nonundefined)
      - binary(ascii), binary(asciiprintable), binary(nonempty),
        binary(ascii,nonempty), binary(asciiprintable,nonempty)
      - list(nonempty)
      - proplist(nonempty)
      - string(ascii), string(asciiprintable), string(nonempty),
        string(ascii,nonempty), string(asciiprintable,nonempty)
      - term(nonempty), term(nonundefined), term(nonempty,nonundefined)
      - tuple(nonempty)
      - ascii: all items in atom name/string/binary are ASCII values
      - asciiprintable: all items in atom name/string/binary are printable
        ASCII values
      - nonempty: not equal to '', [], <<>>, or {}
      - nonundefined: not equal to 'undefined'
      - type()? for optional types
      - type(){0} for undefined types
    + user-defined ubf contract (and contract checker) primitives
      - atom(), binary(), float(), integer(), and string() constants
      - #record syntax, ##extended_record syntax with automatic erlang record defines
      - integer ranges (min..max, ..max, min..)
      - erlang-based syntax for integers
      - [type()]? for optional lists
      - [type()]+ for mandatory lists
      - [type()]{N}, [type()]{N,}, [type()]{M,N} for length-constrained lists
    + ubf contract type imports
    + ubf server and ubf client
    + stateless server w/simplified plugin handler callbacks
      - For protocols that do not require state transitions: a single
        state called ANYSTATE is used for the contract, and the
        implementation callback function API is a bit less complex.
    + network formats
      * ebf - Erlang Binary Format
      * jsf - Java Script Format
      * etf - Erlang Term Format
    + ???


To do (in medium term)
======================
  - add Thrift (http://incubator.apache.org/thrift/) support
    * Binary Format
    * Compact Format (TBD)
  - add Avro (http://hadoop.apache.org/avro/) support
  - add Google's Protocol Buffers (http://code.google.com/apis/protocolbuffers/) support
  - add Bert-RPC (http://bert-rpc.org/) support
    * BERT-RPC is UBF/EBF with a specialized contract and plugin
      handler implementation for BERT-RPC. UBF/EBF already supports all
      of the BERT data types.
    * UBF is the text-based wire protocol.  EBF is the binary-based
      wire protocol (based on Erlang's binary serialization format).
  - ???

  
To do (in long term)
====================

  - support multiple listeners for a single ubf server
  - ubf contract generators for QuickCheck
  - asynchronous events from client to server
  - n-bidirectional requests/responses over single tcp/ip connection (similiar to smpp)
  - replace plugin manager and plugin handler with gen_server-based
    implementation
  - enable/disable contract checker by configuration
  - eunit tests
  - quickcheck tests  


Credits
=======

Many, many thanks to Joe Armstrong, UBF's designer and original
implementor.

Gemini Mobile Technologies, Inc. has approved the release of its
extensions, improvements, etc. under an MIT license.  Joe Armstrong
has also given his blessing to Gemini's license choice.