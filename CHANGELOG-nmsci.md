# Changelog

Changelog about new releases of our software landscape 

## [2024.3.7] - 2024.12.17

- LF fix

## [2024.3.6] - 2024.12.13

- oom fix in DHP (MolPrep) for larger molecules with pyscf; required changes in QP as well

## [2024.3.5] - 2024.12.06

- geometric engine will be used by default for geometry optimization. Convergence, grids and symmetry settings were changed.
- added an option to add a DFT preoptimization (like SVP before TZVP), which is not activated by default
- affected modules: MolPrep, Parametrizer (with Psi4 Engine); QuantumPatch if using geometry optimization and Psi4 Engine

## [2024.3.4] - 2024.11.19

- added entrypoint for tool to estimate number of molecules required to fill a given volume
- changed defaults for scf convergence in PySCF
- fixed crash of IPEA analysis for medium sized system. Aborts ESAnalysis IPEA mode for very small systems

## [SimStackServer 1.5.2] - 2024.11.16

- bugfix in SimStack Server to allow other paths than simstack_workspace

## [2024.3.3} - 2024.11.15

- yet another PBC bugfix

## [2024.3.2] - 2024.11.15

- QP bugfix for shell setup -> in line with changes for wanos
- QP bugfix for PBC for sparse systems
- Fixed output indirection in pyscf

## [2024.3] - 2024.11.06

- QP fixes for IP EA runs, compatible with ESAnalysis WaNo
- QP main entry point to use to determine file format for any-file-input in new MolPrep Wano
- All modules: adapted license check: No license required for < 40 atoms and certain molecules

## [2024.2.4] - 2024.09.05

- Lightforge Coulomb Bugfix release

## [2024.2.3] - 2024.08.05

- Release after bugfix in LF regarding some file system issue

## [2024.2.2] - 2024-07-11

- Rerelease due to cloud licensing issue (Cloud licenses are immediately released now)

## [2024.2.1] - 2024-06-28

- feature QP: PySCF engine in WaNo
- feature QP: storage location in WaNo
- features LF: "generic" mode for couplings including scaling factors

## [2024.1.4] - 2024-05-23

- bugfix: added missing pyscf package

## [2024.1.3] - 2024-05-16

- pyscf support for mobility
- Added cloud licensing scheme

## [2024.1.2] - 2024-02-09

- Added missing dihedralparametrizer package to release

## [2024.1.1] - 2024-01-06

- First release with new tagging format

