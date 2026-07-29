---
v: 3

title: SCHC Compression of VOICI Headers
abbrev: SCHC-VOICI-Profile
docname: draft-lampin-schc-voici-compression-latest
submissionType: IETF

stand_alone: true

ipr: trust200902
area: Internet
wg: schc
keyword: []
category: info

coding: us-ascii

author:
  -
    ins: Q. Lampin
    name: Quentin Lampin
    org: Orange
    street: Orange 3 Massifs - 22 Chemin du Vieux Chene
    city: Meylan
    code: 38240
    country: France
    email: quentin.lampin@orange.com

normative:
  RFC8724: SCHC

informative:
  VOICI: I-D.draft-lampin-schc-voici-00
  ARCH: I-D.draft-ietf-schc-architecture-06


--- abstract

This document describes how to compress VOICI headers using SCHC rules
at a lower stratum, demonstrating that VOICI provides explicit routing
metadata that is transparently compressed to minimal on-wire size while
preserving standardized dispatch semantics. It is intended as a
reference for implementers deploying VOICI in SCHC-based networks
and does not modify the VOICI specification itself.

--- middle

# Introduction

The VOICI link multiplexer [VOICI] provides a standardized
transport header that carries session identification, content mechanism 
dispatch, and optional integrity protection with a minimal 1-byte header in the
common case.

When VOICI is carried over a link where SCHC {{RFC8724}} is also used for header
compression, a lower SCHC stratum can compress the VOICI header itself.
This document describes the SCHC rules that achieve this compression
and demonstrates how VOICI provides explicit routing metadata that is
transparently compressed, achieving minimal on-wire overhead while
preserving standardized dispatch semantics.

# Terminology

This documents follows the terminology described in {{ARCH}}.

# VOICI Header Layout

The VOICI header is defined in ~[VOICI].  For reference, the minimal
header (no optional fields, inline Session ID) is a single byte:

~~~
 0 1 2 3 4 5 6 7   bit
+-+-+-+-+-+-+-+-+
|V|O|I|CI |S S S|
+-+-+-+-+-+-+-+-+
~~~
{: #fig-voici-minimal-header title="VOICI minimal header"}

The full header, including all optional fields, is:

~~~
 0                   1                   2
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3   bits
+-+-+-+---+-----+ - - - - - - - - - - - - - - - +
|V|O|I|CI | SSS |         Session ID (long)     |
+-+-+-+---+-----+ - - - - - - - - - - - - - - - +
+- - - - - - - - - - - - - - - -+
|              CRC              | (optional, I=1)
+- - - - - - - - - - - - - - - -+
+- - - - - - - - - - - - - - - -+ (optional, O=1,
|    Original EtherType/Port    |  2B for ET/UDP port,
+- - - - - - - - - - - - - - - -+  1B for IPv6 NH)
~~~
{: #fig-voici-header title="VOICI header format"}

The first byte is always present.  The V-O-I flags (3 bits), CI field
(2 bits), and SSS field (3 bits) form the mandatory header.  The
optional fields are present only when their corresponding flags are set:

* **V** (1 bit): Header version.  V=0 for the current specification.
* **O** (1 bit): Original EtherType/Port flag.  When set, the Original
  EtherType/Port field is present at the end of the header.
* **I** (1 bit): Integrity flag.  When set, a 2-byte CRC-16 field is
  present after the Session ID.
* **CI** (2 bits): Content Identifier.  CI=0 for unprocessed/raw, CI=1
  for SCHC, CI=2 reserved, CI=3 for extended CI.
* **SSS** (3 bits): Session ID prefix.  Values 0-6 represent inline
  Session IDs; value 7 triggers a LEB128 extension in the following
  byte(s) with offset +7.
* **Session ID (long)**: Variable-length LEB128-encoded Session ID,
  present only when SSS=7 (or when CI=3 for extended CI).
* **CRC**: 16-bit CRC-16 integrity check, present only when I=1.
* **Original EtherType/Port**: 1-2 bytes carrying the original
  EtherType, IPv6 Next Header, or UDP port number, present only when
  O=1.

For the common case (V=0, O=0, I=0, CI=1 for SCHC, SSS=0 for Session 0),
the byte value is:

~~~
  V=0, O=0, I=0, CI=01, SSS=000  =>  0b00001000  =>  0x08
~~~

For Session 1 (SSS=1), the byte value is 0x09.  The full range of inline
sessions (0-6) with CI=0b001 (SCHC Content) maps to bytes 0x08 through 0x0E.

# SCHC Compression Rules for VOICI

## Field Identifiers

To write SCHC compression rules for the VOICI header, the following
Field Identifiers (FIDs) are defined.  These FIDs reference specific
sub-fields of the VOICI header byte, as well as optional extension
fields:

| FID             | Field                     | Size      |
|-----------------|---------------------------|-----------|
| VOICI.V         | Version                   | 1 bit     |
| VOICI.O         | Original ET/Port flag     | 1 bit     |
| VOICI.I         | Integrity flag            | 1 bit     |
| VOICI.CI        | Content Identifier        | 2 bits    |
| VOICI.SSS       | Session ID prefix         | 3 bits    |
| VOICI.SID       | Session ID (LEB128)       | variable  |
| VOICI.EXT_CI    | Extended CI (LEB128)      | variable  |
| VOICI.CRC       | CRC-16                    | 16 bits   |
| VOICI.ORIG_EP   | Original ET/Port          | 1-2 bytes |
{: #tab-voici-fids title="VOICI header fields IDs for SCHC"}


The per-field FIDs (VOICI.V through VOICI.SSS) enable SCHC compression
rules that elide known sub-fields while preserving the Session ID
identifier required for dispatch, original EtherType/NextHeader/Port and
CRC when present.


## Scenario A: Single Session (0-bit residue) with minimal VOICI header

These examples illustrate a stratum scoped to the VOICI header alone.
If the stratum spans multiple headers (e.g., `[IPv6 | VOICI]`),
additional Field Descriptors are required for those headers (as shown
in the concrete example).  When only one session exists on the link,
the minimal VOICI header has fully deterministic content, and per-field rules
elide each sub-field individually.

|     FID   |FL| FP|DI| TV    |  MO   |    CDA   |
|-----------|--|---|--|-------|-------|----------|
| VOICI.V   | 1| 1 |Bi| 0b0   | equal | not-sent |
| VOICI.O   | 1| 1 |Bi| 0b0   | equal | not-sent |
| VOICI.I   | 1| 1 |Bi| 0b0   | equal | not-sent |
| VOICI.CI  | 2| 1 |Bi| 0b01  | equal | not-sent |
| VOICI.SSS | 3| 1 |Bi| 0b000 | equal | not-sent |
{: #tab-voici-minimal-compression-1ss title="VOICI minimal header C/D rule, 1 session"}

  Residue: 0 bits (all fields elided)

## Scenario B: Two Sessions (1-bit residue)

When two sessions are multiplexed -- Session IDs 0 and 1 mapped to SSS values
0b000 and 0b001, the session identifier must be preserved. A 1-bit residue is 
achieved by eliding the known flag and CI bits while preserving SSS via MSB
matching:


|     FID   |FL| FP|DI| TV   |  MO   |    CDA   |
|-----------|--|---|--|------|-------|----------|
| VOICI.V   | 1| 1 |Bi| 0b0  | equal | not-sent |
| VOICI.O   | 1| 1 |Bi| 0b0  | equal | not-sent |
| VOICI.I   | 1| 1 |Bi| 0b0  | equal | not-sent |
| VOICI.CI  | 2| 1 |Bi| 0b01 | equal | not-sent |
| VOICI.SSS | 3| 1 |Bi| 0b00 | MSB(2)|    LSB   |
{: #tab-voici-minimal-compression-2sess title="VOICI minimal header C/D rule, 2 sessions"}


  - Session 0 (SSS=0b000) -> MSB(2) match -> residue: 0
  - Session 1 (SSS=0b001) -> MSB(2) match -> residue: 1

  Residue: 1 bit

## Extended Scenarios

### Multiple Sessions with Inline IDs

For up to 7 inline sessions (SSS values 0-6), the per-field approach with 
MO/CDAs Match-Mapping, Mapping-Sent or Ignore/Value-Sent on SSS can encode 
any number of sessions:

* 2 sessions (SSS 0-1): MSB(2) match -> 1 bit residue
* 3-4 sessions (SSS 0-3): MSB(1) match -> 2 bits residue
* 5-7 sessions (SSS 0-6): Ignore/Value-Sent -> 3 bits residue


### Sessions Beyond Inline Range

For sessions with SSS=7 (LEB128 extension), the compressor must
handle the variable-length Session ID field.  A VOICI-aware compressor
can preserve the LEB128-encoded Session ID as a variable-length residual field,
producing a residue proportional to the Session ID magnitude: 12 bits for 
Session IDs 7-134, 20 bits for 135-65535 (4bits encoded length + 1 or 2 bytes of
LEB128-encoded Session ID).

|     FID   |FL | FP|DI| TV    |  MO    |    CDA     |
|-----------|---|---|--|-------|--------|------------|
| VOICI.V   | 1 | 1 |Bi| 0b0   | equal  |  not-sent  |
| VOICI.O   | 1 | 1 |Bi| 0b0   | equal  |  not-sent  |
| VOICI.I   | 1 | 1 |Bi| 0b0   | equal  |  not-sent  |
| VOICI.CI  | 2 | 1 |Bi| 0b01  | equal  |  not-sent  |
| VOICI.SSS | 3 | 1 |Bi| 0b111 | equal  |  not-sent  |
| VOICI.SID |VAR| 1 |Bi|       | ignore | value-sent |
{: #tab-voici-minimal-compression-extsess title="VOICI minimal header C/D rule, Extended Session ID"}

  Residue: 12-20 bits


Alternatively, specific rules for each sub-range can be derived setting the 
Field Length to 8 and 16 bits respectively to match Session IDs 7-134 and 
135-65535 respectively, reducing the residue to 8 or 16 bits.

# Concrete Example: Multi-Stratum Deployment

This section illustrates a deployment using multiple SCHC strata and
VOICI for inter-stratum session multiplexing.  It demonstrates how
VOICI provides explicit dispatch metadata that is transparently compressed
by a lower stratum, achieving minimal on-wire overhead.

## Deployment Scenario

The example deployment consists of a 6Lo mesh network with a 6LN (end device),
a 6LR (mesh router), and a 6LBR (border router).  Beyond the 6LBR,
a Server hosting both CoAP and CoAPS resides on the Internet.

The 6LN sends unencrypted CoAP traffic to the Server on UDP port 5683 and 
encrypted CoAPS traffic to the same Server on UDP port 5684.

### SCHC Considerations

The 6LN participates in 3 SCHC Sessions, Sess.0, Sess.1 and Sess.2.

The 6LR and 6LBR participate in the SCHC Session Sess.0 only and the Server
participates in Sessions Sess.1 and Sess.2.

- Sess.1 and Sess.2 and corresponding Contexts are managed by a first actor,
for instance a utility company that operates the Server. Both are executed on 
the same Endpoint that uses VOICI as the Dispatcher.

- Sess.0 and corresponding Context is managed by the Network Operator of
  the 6Lo Network. Having a single Session, the corresponding Endpoint 
  dispatches SCHC Data Units directly to the appropriate Instance.

~~~~~~~~
                                                                      
+-------+                   +-------+ SCHC     +--------+             
|  6LN  | SCHC Sess.0       | 6LBR  | Sess.0   | Server | SCHC Sess.1 
|       |      Sess.1       |       |          |        |      Sess.2 
|       |      Sess.2  +----|       |----------+        |             
|       |              |    |       |          |        |             
+---+---+              |    +-------+          +--------+             
    |                  |                                              
    |              +---+---+                                          
    |              |  6LR  | SCHC                                     
    +--------------+       | Sess.0                                   
                   |       |                                          
                   |       |                                          
                   +-------+                                          
                                                                      
          6Lo Network           |           Internet                  
~~~~~~~~
{: #fig-scenario-overview title="Example deployment scenario"}

The deployment uses three SCHC strata:

* **Upper Stratum 1**: Compresses `[UDP | CoAP]`  in Session 1
* **Upper Stratum 2**: Compresses `[UDP | CoAPS]` in Session 2
* **Lower Stratum**: Compresses `[IPv6 | VOICI]` in Session 0

## SCHC processing at the 6LN

The following figure illustrates the 3 SCHC Strata and 3 Instances on the 6LN
host.

1. Inst.1 compresses UDP/CoAP and produces the SCHC Data Unit SCHC Dat.1
   Inst.2 compresses UDP/CoAPS and produces the SCHC Data Unit SCHC Dat.2

2. VOICI encapsulates SCHC Dat.1 with SSS:=0b000 or SCHC Dat.2 with SSS:=0b001.
   IPv6 Next Header is set to SCHC.

3. Inst.0 compresses IPv6/VOICI and produces SCHC Dat.0
   VOICI.SSS MO/CDA set to msb/lsb and TV set to 0b00


~~~~~~~~
         +- +-----+-----+ -+          
Sess.ID1 |  |CoAP |CoAPS|  | Sess.ID2 
         |  +-----+-----+  |          
     +---|  |    UDP    |  |---+      
     |   +- +-----------+ -+   |      
     |                         |      
     |                         |      
     |                         |      
 +---+------+           +------+---+  
 |SCHC Dat.1|           |SCHC Dat.2|  
 +-----+----+           +----+-----+
       |                     |  
       +-----------+---------+        
       SSS:0b000   |  SSS:0b001       
          +- +-----+------+           
Sess.ID0  |  |    VOICI   |           
          |  +------------+           
       +--|  |    IPv6    |           
       |  +- +------------+           
       |                        
  +----+-----+                  
  |SCHC Dat.0|                  
  +----------+   
~~~~~~~~
{: #fig-scenario-6ln title="VOICI header compressed at the 6LN"}

## SCHC Datagrams on the 6Lo Network

The following Figure illustrates how the Data Units are transported over the
6Lo network.

4. 6LN encapsulates the resulting PDU, that is the concatenation of SCHC 
   Dat.0 and SCHC Dat.1/2, in the 802.15.4 payload with the SCHC Dispatch byte 
   set and sends it to 6LR.

5. 6LR detects the SCHC dispatch byte and dispatches the frame to
   Inst.0. Inst.0 decompresses SCHC Dat.0, retrieves IPv6 header
   (and VOICI) and forwards to 6LBR.

6. 6LBR detects the SCHC dispatch byte and dispatches the frame to
   Inst.0. Inst.0 decompresses SCHC Dat.0, reconstructs IPv6 and
   VOICI headers. 6LBR forwards the IPv6 frame to its destination,
   outside of the 6Lo network.
   
~~~~~~~~
                  +------------+                   
      Inst.0     +-|->  IPv6   -|-+               
    decompresses | +------------+ |               
                |                |         
+------------+  | +------------+ | +------------+
|SCHC Dat.1/2|  | |SCHC Dat.1/2| | |SCHC Dat.1/2|
+------------+  | +------------+ | +------------+ Inst.0 reconstructs
|SCHC Dat.0  |  +-|-SCHC Dat.0 | | |SCHC Dat.0--|---------+
+------------+    +------------+ | +------------+         |
|    6Lo     |    |    6Lo     | | |    6Lo     |         v
+------------+    +------------+ | +------------+   +------------+ 
|  802.15.4  |    |  802.15.4  | | |  802.15.4  |   |    VOICI   | 
+-----+------+    +-------+----+ | +------------+   +------------+ 
      |                ^  |      v        ^         |    IPv6    | 
      |  6LN forwards  |  |  6LR forwards |         +------------+ 
      +-----to-6LR-----+  +----to-6LBR----+          
                                                        
    6LN                 6LR                   6LBR                   
~~~~~~~~
{: #fig-scenario-6lo-network title="VOICI compressed on 6Lo Network"}

## Transport over the Internet and processing at the Server

The following Figure illustrates the SCHC datagrams transported over the 
Internet in IPv6 frames and how they are processed at the Server.

7. 6LBR forwards the IPv6 frame to the Server

8. The Server Endpoint dispatches the SCHC Dat. to Inst.1/2 based on
   VOICI.SSS value. SCHC Datagrams identified by VOICI.SSS = 0b000 are
   dispatched to Inst.1 which decompresses UDP and CoAP and those with 
   VOICI.SSS= 0b001 are dispatched to Inst.2 which decompresses UDP and
   CoAPS. 
   
9. The Original IPv6 Next Header value is restored to its original value 
   (UDP,17) and the frame is handled by UDP which delivers the reconstructed
   UDP datagram to the application.
   
10. The CoAP(S) application server processes the message.

~~~~~~~~
                                          +-------+          
                                          | CoAP  |          
                                          +-------+          
                                          |  UDP  |          
                                          +-------+          
                                              ^              
    +------------+     +------------+         | SSS:0b000    
    |SCHC Dat.1/2|     |SCHC Dat.1/2|---------+              
    +------------+     +------------+         | SSS:0b001    
    |    VOICI   |     |    VOICI   |         v              
    +------------+     +------------+     +-------+          
    |    IPv6    |     |     IPv6   |     | CoAPS |          
    +------------+     +------------+     +-------+          
    |     Eth.   |     |     Eth.   |     |  UDP  |          
    +------+-----+     +------^-----+     +-------+          
           |                  |                              
           |  6LBR forwards   |                              
           +----to-Server-----+                              
                                                             
        6LBR                        Server                   
~~~~~~~~
{: #fig-scenario-internet title="IPv6 frame & VOICI dispatch at the Server"}

## Formats 

Before any compression, the packet contains standard IPv6/UDP/CoAP with the
following IPv6 addresses, fd00:1::4 for the 6LN and 2001:db8::13 for the Server.


### Upper Stratum Compression

Each upper stratum compresses its respective UDP/CoAP headers independently.
After upper compression, VOICI encapsulates the upper SCHC datagram with a
Session ID that routes it to the correct upper context at the receiver:

-  **Session 1**: VOICI byte = `0x08` (V=0, O=0, I=0, CI=01, **SSS=000**)
-  **Session 2**: VOICI byte = `0x09` (V=0, O=0, I=0, CI=01, **SSS=001**)

The IPv6 Next Header field is set to indicate the presence of SCHC-compressed 
data (i.e., the SCHC IP Protocol Number).

The intermediate packet handed to the lower stratum looks like:

~~~
  [CoAP Payload]
  [Upper SCHC Residue]
  [VOICI Header (SSS=0 or SSS=1)]
  [IPv6 Header (NH=SCHC)]
~~~
{: #fig-scenario-upper-stratum-packet-layout title="Header layout of PDU compressed by Seesion 0"}


### Lower Stratum Compression

The lower stratum compresses the IPv6 and VOICI headers jointly using a single 
Rule. With only one lower stratum Rule, the Rule ID is zero-length; 
discrimination between the two upper sessions is carried in the 1-bit residue 
from the VOICI.SSS field (MSB(2) with LSB CDA).

**Rule (Session 0)**


|      FID        |  FL | FP|DI|      TV      |   MO   |    CDA   |
|-----------------|-----|---|--|--------------|--------|----------|
| IPv6 Ver        |   4 | 1 |Bi|      6       | equal  | not-sent |
| IPv6 Traffic Cl.|   8 | 1 |Bi|      0       | equal  | not-sent |
| IPv6 Flow Label |  20 | 1 |Bi|      0       | equal  | not-sent |
| IPv6 Length     |  16 | 1 |Bi|              | ignore | compute-*|
| IPv6 Next Header|   8 | 1 |Bi|   \<SCHC\>   | equal  | not-sent |
| IPv6 Hop Limit  |   8 | 1 |Bi|      64      | equal  | not-sent |
| IPv6 Src Addr   | 128 | 1 |Bi|   fd00:1::4  | equal  | not-sent |
| IPv6 Dst Addr   | 128 | 1 |Bi| 2001:db8::13 | equal  | not-sent |
| VOICI.V         |   1 | 1 |Bi|      0b0     | equal  | not-sent |
| VOICI.O         |   1 | 1 |Bi|      0b0     | equal  | not-sent |
| VOICI.I         |   1 | 1 |Bi|      0b0     | equal  | not-sent |
| VOICI.CI        |   2 | 1 |Bi|     0b01     | equal  | not-sent |
| VOICI.SSS       |   3 | 1 |Bi|     0b00     | MSB(2) |   LSB    |
{: #tab-voici-example-rule-sess0 title="Session 0 C/D rule for IPv6/VOICI"}

  Residue: 1 bit

### On-the-Wire Result

The resulting 802.15.4 payload is:

~~~
+-------------+------------------+---------------------------------+
|SCHC Dispatch|Lower SCHC Residue|Upper SCHC Residue| CoAP Payload |
| (01000100)  |      (1bit)      |                  |  (raw)       |
+-------------+------------------+---------------------------------+
~~~
{: #fig-example-6lo-frame title="802.15.4 payload on the 6Lo network"}


# Security Considerations

The SCHC compression of VOICI headers does not introduce new security
considerations beyond those of the base VOICI specification ~[VOICI]
and SCHC ~[RFC8724].  The compression rule described in this document
preserves the integrity of the VOICI Header.


# IANA Considerations

This document has no IANA actions.  The Field Identifiers defined herein
are informational references for implementers writing SCHC compression
rules for VOICI headers.

--- back
