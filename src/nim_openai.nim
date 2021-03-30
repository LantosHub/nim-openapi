import httpclient
import json
import strformat
import argparse
import os

type
  OpenAIEngine = enum
    ada = "ada"
    babbage = "babbage"
    curie = "curie"
    davinci = "davinci"
    davinciInstructBeta = "davinci-instruct-beta"
    urieInstructBeta = "curie-instruct-beta"

  OpenAIQueryType = enum
    completion,
    search,
    generate

  OpenAIClient = object
    httpClient: HttpClient
    baseUrl: string
    token: string

  OpenAIRequest = object
    prompt: string
    stream: bool
    stop: seq[string]
    max_tokens: int
    temperature: float
    top_p: float
    presence_penalty: float
    frequency_penalty: float
    best_of: int
    # n: string
    logprobs: int


# default engine is davinci
proc getBaseURL(engine: OpenAIEngine = davinci, query: OpenAIQueryType = completion): string =
  case query:
  of search: 
    fmt"https://api.openai.com/v1/engines/{engine}/search"
  of completion: 
    fmt"https://api.openai.com/v1/engines/{engine}/completions"
  of generate: 
    fmt"https://api.openai.com/v1/engines/{engine}/genenoration"

proc newOpenAIClient*(
  token: string,
  baseUrl: string
): OpenAIClient =
  let client = newHttpClient()
  client.headers = newHttpHeaders({
    "Content-Type": "application/json",
    # remove this make into func
    "Authorization": fmt"Bearer {token}"
  })
  OpenAIClient(
    httpClient: client,
    baseUrl: baseUrl,
    token: token
  )

proc newOpenAIClient*(
  token: string,
  engine: OpenAIEngine,
  query: OpenAIQueryType = completion
): OpenAIClient =
  newOpenAIClient(
    token,
    getBaseURL(engine, query)
  )


# find new name for this
proc request*(openAIClient: OpenAIClient, openAIRequest: OpenAIRequest): Response =
  openAIClient.httpClient.request(
    openAIClient.baseUrl,
    httpMethod = HttpPost,
    # body = $$request
    body = $(%openAIRequest)
  )
  
when isMainModule:
  # let env = initDotEnv()
  # env.load()
  var token = os.getEnv("OPENAI_API_KEY")
  var openAIClient = newOpenAIClient(
    token=token,
    # baseUrl="http://localhost:5000/"
    engine= davinci,
    query= completion
  )
  var req = OpenAIRequest()
  
  req.prompt="""This conversation is with an AI assistant. The Ai Assistant is helpful, truthful, smart and very frieldy .
    Human: What is One-Time Pad decryption?
    """
  req.stop= @["\n", "Human:", "AI:"]
  req.max_tokens=200
  req.temperature=0.9
  req.top_p = 1
  req.presence_penalty = 0.6
  req.frequency_penalty = 0
  req.best_of=3
  req.logprobs=1
  req.stream = false
  echo pretty(%req)

  var res = openAIClient.request(req)
  echo res.headers
  echo res.body
  echo res.status
  