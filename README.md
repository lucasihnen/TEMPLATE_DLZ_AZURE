# TEMPLATE_DLZ_MAS

Repositiorio para crear una Data Landing Zone (DLZ) en Azure para una suscripción.

Los elementos creados son:
- Tres grupos de recursos, para cada ambiente (dev, qa, prd)
- Dentro de cada grupo de recursos se crea:
    - Una storage account
        - Un container de raw-data, silver-data y gold-data en cada uno
    - Un Azure SQL Server y Single Database
    - Un Synapse Analytics
    - Un Data Factory
    - Un Azure Key Vault

Para utilizar el repositorio se tiene que seguir la siguiente guía:
- INSERTAR LINK DE LA GUIA CUANDO ESTE LOLXD