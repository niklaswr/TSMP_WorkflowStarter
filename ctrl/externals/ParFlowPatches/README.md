<!---
author: Niklas WAGNER
e-mail: n.wagner@fz-juelich.de
version: 2021-03-15
-->

Within this directory individual source-code changes for the ParFlow model are tracked. Those source-code changes are highly individual and written / applied for and to specific setups only. So DO NOT apply those to your setup without thinking.
The reason why those changes are tracked here is mainly the reusability of each setup, which also includes the used TSMP and related component model version.
A further, but maybe minor, reason is to save those changes for potential later integration to TSMP. E.g. if some of the changes tracked here are used over and over again for different setups, we can hand over those patch files to SLTS which should make their life easier (in terms of integrating) and speed things up for us.

If you do not already known about `diff` and `patch` please read first about it e.g. in this article:
https://www.pair.com/support/kb/paircloud-diff-and-patch/
Further please do follow this diff/patch structure for some consistency:
>> diff -u ORIGFILE CHANGEDFILE > PATH/TO/PATCHFILE
>> patch FILE2PATCH PATCHFILE

Currently tracked changes:
1) patch2writeSourceAndSinksWithoutCLM
Within the realm of TSMP and coupling via OASIS ParFlow is compiled without the internal CLM. Therefore it is not possible to dumpe the source and sink terms of ParFlow as e.g. et.
However this information is needed to calculate the full water-balance, which is why we changed the source-code of ParFlow to print this information even without CLM compiled.

2) patch2runEvapTransWhileCoupledWithTSMP
Within the realm of TSMP and coupling via OASIS ParFlow is compiled without the internal CLM and therefore EvapTransTransient functionality is not available. However we do need this functionality to pass irrigation information to ParFlow. So we changed the ParFlow source-code again to enable EvapTransTransient.

