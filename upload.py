import requests

import os

ARTIFACTS_CACHE_BASE = "https://artifactcache.actions.githubusercontent.com/"
APIS_POSTFIX = "/_apis/"
ARTIFACTS_CACHE_API = APIS_POSTFIX + "artifactcache/cache"

#https://github.com/actions/toolkit/blob/main/packages/cache/src/cache.ts

def getArtifactsCacheEndpoint(shittyId, key: str, version: str):
	"""version looks like SHA256 hash"""
	return ARTIFACTS_CACHE_API + shittyId + ARTIFACTS_CACHE_API + "?keys=" + key + "&version=" + version



PIPELINES_BASE = "https://pipelines.actions.githubusercontent.com/"
APIS_POSTFIX = "/_apis/"
PIPELINES_APIS = "pipelines/"
PIPELINES_WORKFLOWS_API = PIPELINES_APIS + "workflows/"
CONTAINERS_APIS = "resources/Containers/"



#ACTIONS_CACHE_URL
#ACTIONS_RUNTIME_TOKEN


someId = # ID of length of 50
workflowId = os.environ["GITHUB_RUN_ID"]


def makeACTIONS_RUNTIME_BASE(someId: str):
	return PIPELINES_BASE + someId + APIS_POSTFIX


#ACTIONS_RUNTIME_BASE = makeACTIONS_RUNTIME_BASE(someId)
ACTIONS_RUNTIME_BASE = os.environ["GITHUB_RUN_ID"]
print(os.environ)


def getWorkflowsAPIs(workflowId: int):
	return ACTIONS_RUNTIME_BASE + PIPELINES_WORKFLOWS_API + str(workflowId)


def getArtifactsAPI(workflowId: int):
	return getWorkflowsAPIs(workflowId) + "/artifacts?api-version=6.0-preview"


artifactsURI = getArtifactsAPI(someId, workflowId)

artifactsHeaders = [
	{"name": "accept", "value": "application/json;api-version=6.0-preview"},
	{"name": "content-type", "value": "application/json"},
	{"name": "user-agent", "value": "miniGHAPI"},
]


def createArtifactContainer(artifactFileName, days: int=None):
	reqObj = {"Type": "actions_storage", "Name": artifactFileName}
	if days is not None:
		maxRetentionDays = int(os.environ["GITHUB_RETENTION_DAYS"])
		if days > maxRetentionDays:
			raise ValueError("Retention for " + str(days) + " is not allowed for this repo")
		reqObj["RetentionDays"] = days
	res = requests.post(artifactsURI, reqObj).json()
	return res["fileContainerResourceUrl"]  # "https://pipelines.actions.githubusercontent.com/${shittyId}/_apis/resources/Containers/${containerId}",
	return res["containerId"], res["expiresOn"]


def getPutURI(containerId, containerName, fileName):
	return ACTIONS_RUNTIME_BASE + CONTAINERS_APIS + str(containerId) + "?itemPath=" + urllib.quote(containerName + "/" + fileName)


def putArtifact(container, fileContents):
	return requests.put(getPutURI(), fileContents).json()
	#{"containerId": 266701, "scopeIdentifier": "00000000-0000-0000-0000-000000000000", "path": "test.txt/test.txt", "itemType": "file", "status": "created", "fileLength": 5, "fileEncoding": 1, "fileType": 1, "dateCreated": <ISO date time string>, "dateLastModified": <ISO date time string>, "createdBy":  <guid>, "lastModifiedBy": <guid>, "fileId": 1207, "contentId": ""}


def getArtifactPatchURI():
	return artifactsURI + "&" + "artifactName=test.txt"


def patchArtifact(dic: dict):
	return requests.patch(getArtifactPatchURI(), dic).json()


def uploadArtifact(fileContents):
	createArtifactContainer()
	putArtifact()
	#patchArtifact({"Size": len(fileContents)})  # seems to be unneeded
