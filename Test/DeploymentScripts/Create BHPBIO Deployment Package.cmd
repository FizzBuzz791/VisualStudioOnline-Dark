REM ***** Configuration Settings *****

SET BuildVersion=4.0.3.1
SET BuildDropFolder="L:\Reconcilor_BHPBIO\Test\Specific\"%BuildVersion%""
SET BuildDropFolderRelease="%BuildDropFolder%\Release"
SET BuildDropFolderx86="%BuildDropFolder%\x86\Debug"

SET LocalSourceFolder=C:\Dev\Reconcilor_BHPBIO\Branch-4.0.0.0\Test
SET PackageOutputFolder=.\ReconcilorBHPBIO-%BuildVersion%

REM ***** Initialisation *****


REM ***** Create folder structure *****

rmdir /s /q %PackageOutputFolder%
mkdir %PackageOutputFolder%
mkdir %PackageOutputFolder%\Site
mkdir %PackageOutputFolder%\Site\ReconcilorBhpbio
mkdir %PackageOutputFolder%\Database
mkdir %PackageOutputFolder%\Service
mkdir %PackageOutputFolder%\Reports
mkdir %PackageOutputFolder%\Reports\Linked
mkdir %PackageOutputFolder%\Reports\SSRSUpload

REM ***** Copy Service Files *****

copy %BuildDropFolderx86%\*.exe %PackageOutputFolder%\Service
copy %BuildDropFolderx86%\*.dll %PackageOutputFolder%\Service
copy %BuildDropFolderx86%\*.xml %PackageOutputFolder%\Service
copy %BuildDropFolderx86%\*.xaml %PackageOutputFolder%\Service
copy %BuildDropFolderx86%\*.config %PackageOutputFolder%\Service
rename %PackageOutputFolder%\Service\*.config Development.*.config

REM ***** Copy Website Files *****

xcopy /E %BuildDropFolderRelease%\_PublishedWebsites\ReconcilorBhpbio\*.* %PackageOutputFolder%\Site\ReconcilorBhpbio
rename %PackageOutputFolder%\Site\ReconcilorBhpbio\web.config development.web.config

REM ***** Copy Database Files *****

copy %BuildDropFolderRelease%\ReconcilorBhpbio.dbd %PackageOutputFolder%\Database
copy %BuildDropFolderRelease%\db-ReconcilorBhpbio-artefacts\*.sql %PackageOutputFolder%\Database

REM ***** Copy Reports *****
copy %BuildDropFolderRelease%\Reports\*.* %PackageOutputFolder%\Reports
copy %BuildDropFolderRelease%\Reports\Linked\*.* %PackageOutputFolder%\Reports\Linked
copy %BuildDropFolderRelease%\Reports\SSRSUpload\*.* %PackageOutputFolder%\Reports\SSRSUpload


REM ***** Copy deployment tools & scripts *****

copy %LocalSourceFolder%\DeploymentScripts\*Reports.cmd %PackageOutputFolder%\Reports
copy %LocalSourceFolder%\DeploymentScripts\*Reports.rss %PackageOutputFolder%\Reports
copy %LocalSourceFolder%\DeploymentScripts\*Report.rss %PackageOutputFolder%\Reports

