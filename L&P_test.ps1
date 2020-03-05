$DIR = "PS"

if (Test-Path C:\$DIR -PathType Container)
{
	$child_items = ([array] (Get-ChildItem -Path C:\$DIR -Recurse -Force))
        if ($child_items) {
            $null = $child_items | Remove-Item -Force -Recurse
        }
        $null = Remove-Item C:\$DIR -Force
		
	Remove-Item -LiteralPath C:\$DIR -Force -Recurse
	mkdir C:\$DIR
}
else
{
	mkdir C:\$DIR
}

CLS

ECHO "DOWNLOADING THE FILES REQUIRED TO THIS ACTION....."

if (-not ([System.Management.Automation.PSTypeName]'ServerCertificateValidationCallback').Type)
{
$certCallback = @"
    using System;
    using System.Net;
    using System.Net.Security;
    using System.Security.Cryptography.X509Certificates;
    public class ServerCertificateValidationCallback
    {
        public static void Ignore()
        {
            if(ServicePointManager.ServerCertificateValidationCallback ==null)
            {
                ServicePointManager.ServerCertificateValidationCallback += 
                    delegate
                    (
                        Object obj, 
                        X509Certificate certificate, 
                        X509Chain chain, 
                        SslPolicyErrors errors
                    )
                    {
                        return true;
                    };
            }
        }
    }
"@
    Add-Type $certCallback
 }
[ServerCertificateValidationCallback]::Ignore()

Invoke-WebRequest "https://ec2-18-235-65-145.compute-1.amazonaws.com/concerto/downloads/scommand/scommand.zip" -OutFile "C:\$DIR\scommand.zip"
Expand-Archive -LiteralPath C:\$DIR\scommand.zip -DestinationPath C:\$DIR\
cd C:\$DIR\scommand\bin
ECHO "FILES DOWNLOADED....."
