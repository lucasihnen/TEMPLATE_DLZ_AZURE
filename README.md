# Template Data Landing Zone MAS

Repositiorio para crear una **Data Landing Zone (DLZ) en Azure** para una suscripción definida

Los servicios creados son:
- Un grupo de recurso para cada ambiente que se vaya a crear (lo típico es dev, qa y prd)
- Dentro de cada grupo de recursos se crea:
    - Una storage account
        - Un container de raw-data, silver-data y gold-data en cada uno
    - Un Azure SQL Server y Single Database
    - Un Synapse Analytics
    - Un Data Factory
    - Un Azure Key Vault

Para utilizar el repositorio por primera vez se tiene que seguir la siguiente guía de instalación:
[Setup Bicep](infra-as-code/bicep/resources/guides/Setup_Bicep.md)

La guía de como navegar por el repositorio y ejecutar el script de deployment se puede ver en:
[How to Prepare IAC](infra-as-code/bicep/resources/guides/How_To_Prepare_Client_IAC.md)

La guía de como navegar por el repositorio y ejecutar el script de deployment se puede ver en:
[How to Deploy](infra-as-code/bicep/resources/guides/How_To_Deploy_Client_IAC.md)