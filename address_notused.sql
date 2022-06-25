select
ISNULL(Address.Address1,'')as Address1,
ISNULL(Address.Address2,'')as Address2,
ISNULL(city.Name,'') as city,
ISNULL(state.Code,'') as state,
ISNULL(ZipCode.Code,'')as Zipcode
from client.Contract
	full outer JOIN client.ContractApplicant ON client.Contract.Id = client.ContractApplicant.ContractId    
	full outer JOIN client.Detail ON client.ContractApplicant.ClientId = client.Detail.Id 
	full outer JOIN client.Name ON client.Name.ClientId = client.Detail.Id
	full outer join client.ClientAddress on client.ClientAddress.ClientId = client.[Name].ClientId
	full outer join comn.[Address] on comn.Address.Id = client.ClientAddress.AddressId
	full outer join dbo.ZipCode on comn.Address.ZipCodeId = dbo.ZipCode.Id
	full outer join dbo.City on dbo.ZipCode.CityId = dbo.City.Id
	full outer join dbo.State on dbo.State.Id = dbo.City.StateId
WHERE client.Contract.CompanyId = 278

