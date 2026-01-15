[90mRunning your collection...[39m
postman

Function Exporter

→ Test function to string

  Loading packages...[1/1] 
  ┌
  │ 'function loadUtils(customPkg = null) {\n' +
  │   '    return new Promise((resolve, reject) => {\n' +
  │   "        let lib_url = pm.environment.get('EXTERNAL_
  │ LIB_SERVER') || 'https://tms-api-utils.tmwcloud.com';\
  │ n" +
  │   '        if(customPkg){\n' +
  │   '            lib_url += `?packages=${customPkg}&type
  │ s=custom`;\n' +
  │   '        }\n' +
  │   '        pm.sendRequest({\n' +
  │   '            url: lib_url,\n' +
  │   "            method: 'GET'\n" +
  │   '        }, (err, response) => {\n' +
  │   '            if (!err) {\n' +
  │   '                pkgs = response.text();\n' +
  │   '                //console.log("Received content:", 
  │ pkgs); \n' +
  │   '                eval(pkgs);\n' +
  │   "                pm.globals.set('packages', pkgs);\n
  │ " +
  │   '                resolve(response);\n' +
  │   '            } else {\n' +
  │   "                console.warn('api-governance.loadUt
  │ ils ERROR', err);\n" +
  │   '                return reject(err);\n' +
  │   '            }\n' +
  │   '        });\n' +
  │   '    });\n' +
  │   '}'
  │ 'function cacheOpenAPI(url) {\n' +
  │   '    return new Promise((resolve, reject) => {\n' +
  │   '        pm.sendRequest({\n' +
  │   '            url: url,\n' +
  │   "            method: 'GET'\n" +
  │   '        }, (err, response) => {\n' +
  │   '            if (err) {\n' +
  │   "                console.warn('api-governance.cacheO
  │ penAPI ERROR', err);\n" +
  │   '                return reject(err);\n' +
  │   '            }\n' +
  │   '\n' +
  │   '            let resJson;\n' +
  │   '            try {\n' +
  │   '                resJson = response.json();\n' +
  │   '            } catch (parseErr) {\n' +
  │   "                console.warn('api-governance.cacheO
  │ penAPI JSON Parse Error', parseErr);\n" +
  │   '                return reject(parseErr);\n' +
  │   '            }\n' +
  │   '\n' +
  │   '            try {\n' +
  │   '                utils.direfComponentsSchemas(resJso
  │ n, direfOpenApi => {\n' +
  │   '                    try {\n' +
  │   '                        utils.setGlobalVarsFromOpen
  │ API(direfOpenApi);\n' +
  │   '                        resolve(response);\n' +
  │   '                    } catch (setGlobalErr) {\n' +
  │   "                        console.warn('api-governanc
  │ e.setGlobalVarsFromOpenAPI ERROR', setGlobalErr);\n" +
  │   '                        reject(setGlobalErr);\n' +
  │   '                    }\n' +
  │   '                });\n' +
  │   '            } catch (schemaErr) {\n' +
  │   "                console.warn('api-governance.direfC
  │ omponentsSchemas ERROR', schemaErr);\n" +
  │   '                reject(schemaErr);\n' +
  │   '            }\n' +
  │   '\n' +
  │   '        });\n' +
  │   '    });\n' +
  │   '}'
  │ 'function sendRequest(pm, url, method, header, body) {
  │ \n' +
  │   '    return new Promise((resolve, reject) => {\n' +
  │   '\n' +
  │   '        const expectedStatusCodes = {\n' +
  │   "            'GET': [200],\n" +
  │   "            'POST': [201],\n" +
  │   "            'PUT': [200, 201],\n" +
  │   "            'DELETE': [204]\n" +
  │   '        };\n' +
  │   '\n' +
  │   '        pm.sendRequest({\n' +
  │   '            url: url,\n' +
  │   '            method: method,\n' +
  │   '            header: header,\n' +
  │   "            body: method === 'GET' || method === 'D
  │ ELETE' ? undefined : {\n" +
  │   "                mode: 'application/json',\n" +
  │   '                raw: JSON.stringify(body)\n' +
  │   '            }\n' +
  │   '        },\n' +
  │   '            function (err, response) {\n' +
  │   '                if (err) {\n' +
  │   '                    console.error("sendRequest ERRO
  │ R:", err);\n' +
  │   '                    reject(err);\n' +
  │   '                    return;\n' +
  │   '                }\n' +
  │   '\n' +
  │   '                const validStatusCodes = expectedSt
  │ atusCodes[method] || [200];\n' +
  │   '                if (!validStatusCodes.includes(resp
  │ onse.code)) {\n' +
  │   '                    console.error(`${method} ${url}
  │  sendRequest unexpected status code: ${response.code}`
  │ );\n' +
  │   '                    reject(new Error(`Unexpected st
  │ atus code: ${response.code}`));\n' +
  │   '                    return;\n' +
  │   '                }\n' +
  │   '\n' +
  │   "                if (method === 'DELETE' && response
  │ .code === 204) {\n" +
  │   '                    // DELETE with 204 means succes
  │ s but no content, resolve with true\n' +
  │   '                    resolve(true);\n' +
  │   '                    return;\n' +
  │   '                }\n' +
  │   '\n' +
  │   '                let responseJson;\n' +
  │   '                try {\n' +
  │   '                    responseJson = response.json();
  │ \n' +
  │   '                } catch (e) {\n' +
  │   '                    console.error("api-governance s
  │ endRequest ERROR:", e);\n' +
  │   '                    resolve(false);\n' +
  │   '                    return;\n' +
  │   '                }\n' +
  │   '                resolve(responseJson);\n' +
  │   '            });\n' +
  │   '    });\n' +
  │   '}'
  │ 'function sendGetRequestWithRetry(pm, url, retryAttemp
  │ ts, isSuccessful) {\n' +
  │   '    return new Promise((resolve, reject) => {\n' +
  │   '        pm.sendRequest({\n' +
  │   '            url,\n' +
  │   "            method: 'GET',\n" +
  │   '            header: standardHeader\n' +
  │   '        }, (err, res) => {\n' +
  │   '            if (err) {\n' +
  │   '                return reject(err);\n' +
  │   '            }\n' +
  │   '\n' +
  │   '            const jsonResponse = res.json();\n' +
  │   '            if (isSuccessful(jsonResponse)) {\n' +
  │   '                return resolve(jsonResponse);  // A
  │ lways return the parsed JSON response\n' +
  │   '            }\n' +
  │   '\n' +
  │   '            if (retryAttempts > 0) {\n' +
  │   '                console.log(`Retrying... Attempts l
  │ eft: ${retryAttempts - 1}`);\n' +
  │   '\n' +
  │   '                /* does not work from the Package L
  │ ibrary\n' +
  │   '                setTimeout(() => {\n' +
  │   '                    console.log("Retrying request n
  │ ow...", pm);\n' +
  │   '                    sendGetRequestWithRetry(pm, url
  │ , retryAttempts - 1, isSuccessful)\n' +
  │   '                        .then(resolve)\n' +
  │   '                        .catch(reject);\n' +
  │   '                }, 2000);\n' +
  │   '                */\n' +
  │   '\n' +
  │   '                let start = Date.now();\n' +
  │   '                while (Date.now() - start < 2000);\
  │ n' +
  │   '                    sendGetRequestWithRetry(pm, url
  │ , retryAttempts - 1, isSuccessful)\n' +
  │   '                        .then(resolve)\n' +
  │   '                        .catch(reject);\n' +
  │   '\n' +
  │   '            } else {\n' +
  │   '                console.log("Max retryAttempts reac
  │ hed. Stopping.");\n' +
  │   '                resolve(false);\n' +
  │   '            }\n' +
  │   '        });\n' +
  │   '    });\n' +
  │   '}'
  │ 'function paginationValidation({ pm, paths, querySuffi
  │ x, expectedMessage, delayFn }) {\n' +
  │   '    // Collect eligible GET endpoints\n' +
  │   '    let endpoints = [];\n' +
  │   '    lodash.forEach(paths, (path, url) => {\n' +
  │   "        if (lodash.includes(['/version', '/whoami']
  │ , url)) return;\n" +
  │   '        if (!(filters.urlFilter(url))) return;\n' +
  │   "        let methods = Object.keys(path).filter(key 
  │ => key !== 'parameters');\n" +
  │   "        if (lodash.indexOf(methods, 'get') < 0) ret
  │ urn;\n" +
  │   '\n' +
  │   '        url = url.replace(/{[^}]+}/g, PRE_DEFINE_IN
  │ T_VALUE.toString()) + querySuffix;\n' +
  │   '        endpoints.push(pm.environment.get("DOMAIN")
  │  + url);\n' +
  │   '    });\n' +
  │   '\n' +
  │   '    // Run single request & test\n' +
  │   '    function runTest(url) {\n' +
  │   '        return new Promise(resolve => {\n' +
  │   '            pm.sendRequest({\n' +
  │   '                url: url,\n' +
  │   "                method: 'GET',\n" +
  │   '                header: standardHeader\n' +
  │   '            }, function (err, response) {\n' +
  │   '                if (err) {\n' +
  │   '                    console.error(url, err);\n' +
  │   '                }\n' +
  │   '                const responseJson = (response && r
  │ esponse.text()) ? response.json() : null;\n' +
  │   '                const responseCode = (response && r
  │ esponse.code) ? response.code : null;\n' +
  │   '\n' +
  │   '                pm.test(`pagination validation GET 
  │ ${url}`, function () {\n' +
  │   '                    pm.expect(responseCode).to.equa
  │ l(400);\n' +
  │   '                    pm.expect(responseJson.title).t
  │ o.include(expectedMessage);\n' +
  │   '                });\n' +
  │   '\n' +
  │   '                resolve();\n' +
  │   '            });\n' +
  │   '        });\n' +
  │   '    }\n' +
  │   '\n' +
  │   '    // Chain sequential promises\n' +
  │   '    let chain = Promise.resolve();\n' +
  │   '    endpoints.forEach((ep) => {\n' +
  │   '        chain = chain\n' +
  │   '            .then(() => runTest(ep))\n' +
  │   '            .then(() => delayFn()); // use caller-p
  │ rovided delay\n' +
  │   '    });\n' +
  │   '\n' +
  │   '    return chain.then(() => {\n' +
  │   '        console.log("Pagination validation complete
  │ d for", querySuffix);\n' +
  │   '    });\n' +
  │   '}'
  │ "function test_401(pm, baseUrl, standardHeader, paths,
  │  securityDefinition = 'path') {\n" +
  │   "    const randomJWT = () => [...Array(3)].map(() =>
  │  Math.random().toString(36).substr(2, 10)).join('.');\
  │ n" +
  │   '    lodash.forEach(paths, (path, url) => {\n' +
  │   '        url = url.replace(/{[^}]+}/g, PRE_DEFINE_IN
  │ T_VALUE.toString());\n' +
  │   '        let methods = Object.keys(path);\n' +
  │   '        lodash.forEach(methods, (method) => {\n' +
  │   '\n' +
  │   '            let apiSecurity = path[method].security
  │ ;\n' +
  │   "            if (securityDefinition == 'path' && !ap
  │ iSecurity) {\n" +
  │   '                console.warn(`test_401 Skipping tes
  │ t: No Additional Security Schema found for: ${method} 
  │ ${url}`);\n' +
  │   '                return;\n' +
  │   '            }\n' +
  │   '\n' +
  │   '            method = method.toUpperCase();\n' +
  │   '            pm.sendRequest({\n' +
  │   '                url: baseUrl + url,\n' +
  │   '                method: method,\n' +
  │   '                header: {\n' +
  │   '                    ...standardHeader,\n' +
  │   "                    'Authorization': 'Bearer ' + ra
  │ ndomJWT\n" +
  │   '                }\n' +
  │   '            }, function (err, response) {\n' +
  │   '                if (err) {\n' +
  │   '                    console.error("test_401 error:"
  │ , err);\n' +
  │   '                    return;\n' +
  │   '                }\n' +
  │   '                if (!response) {\n' +
  │   '                    console.warn("test_401 undefine
  │ d response for", method, url);\n' +
  │   '                    return;\n' +
  │   '                }\n' +
  │   '\n' +
  │   '                const responseCopy = JSON.parse(JSO
  │ N.stringify(response));\n' +
  │   '                const responseCode = responseCopy.c
  │ ode;\n' +
  │   '                const responseJson = (response && r
  │ esponse.text()) ? response.json() : null;\n' +
  │   '                //const responseTitle = responseJso
  │ n.title; \n' +
  │   "                pm.test(pm.info.requestName + ': ' 
  │ + method + ' ' + url, function () {\n" +
  │   '                    pm.expect(responseCode).to.equa
  │ l(401);\n' +
  │   "                    //pm.expect(responseTitle).to.e
  │ qual('Unauthorized'); //Trimble Cloud 401 response doe
  │ s not return a response body\n" +
  │   '                });\n' +
  │   '            });\n' +
  │   '        });\n' +
  │   '    });\n' +
  │   '}'
  │ 'function test_404(pm, baseUrl, standardHeader, paths)
  │  {\n' +
  │   '    lodash.forEach(paths, (path, url) => {\n' +
  │   "        url = url.replace(/{[^}]+}/g, '0');\n" +
  │   "        let methods = Object.keys(path).filter(key 
  │ => key !== 'parameters');\n" +
  │   '        let body = null;\n' +
  │   '        lodash.forEach(methods, (method) => {\n' +
  │   '            if (!path.parameters && !utils.inPathPa
  │ rams(path[method].parameters)) {\n' +
  │   '                return;\n' +
  │   '            }\n' +
  │   "  if (method === 'post' || method === 'put') {\n" +
  │   `                let schemaName = path[method].reque
  │ stBody.content["application/json"].schema['$ref'].repl
  │ ace('#/components/schemas/','');\n` +
  │   "                console.log('schemaName',schemaName
  │ );\n" +
  │   "                let tempReqBody = utils.getExampleR
  │ equestBody({'schemaName':schemaName});\n" +
  │   "                //console.log('tempReqBody',tempReq
  │ Body);\n" +
  │   '                body = {\n' +
  │   "                    mode: 'application/json',\n" +
  │   '                    raw: JSON.stringify(tempReqBody
  │ )\n' +
  │   '                };\n' +
  │   '            }\n' +
  │   '\n' +
  │   '            method = method.toUpperCase();\n' +
  │   '            pm.sendRequest({\n' +
  │   '                url: baseUrl + url,\n' +
  │   '                method: method,\n' +
  │   '                header: standardHeader,\n' +
  │   '                body\n' +
  │   '            }, function (err, response) {\n' +
  │   '                if (err) {\n' +
  │   '                    console.error("test_404 error:"
  │ , err);\n' +
  │   '                    return;\n' +
  │   '                }\n' +
  │   '                if (!response) {\n' +
  │   '                    console.warn("test_404 undefine
  │ d response for", method, url);\n' +
  │   '                    return;\n' +
  │   '                }\n' +
  │   '\n' +
  │   '                const responseCopy = JSON.parse(JSO
  │ N.stringify(response));\n' +
  │   '                const responseCode = responseCopy.c
  │ ode;\n' +
  │   '                const responseJson = (response && r
  │ esponse.text()) ? response.json() : null;\n' +
  │   '                const responseTitle = responseJson.
  │ title;\n' +
  │   '\n' +
  │   "                pm.test(pm.info.requestName + ': ' 
  │ + method + ' ' + url, function () {\n" +
  │   '                    pm.expect(responseCode).to.equa
  │ l(404);\n' +
  │   "                    pm.expect(responseTitle).to.equ
  │ al('Not Found');\n" +
  │   '                });\n' +
  │   '            });\n' +
  │   '        });\n' +
  │   '    });\n' +
  │   '}'
  │ 'function test_405(pm, baseUrl, standardHeader, paths)
  │  {\n' +
  │   '    lodash.forEach(paths, (path, url) => {\n' +
  │   '        url = url.replace(/{[^}]+}/g, PRE_DEFINE_IN
  │ T_VALUE.toString());\n' +
  │   '\n' +
  │   "        let validMethods = Object.keys(path).filter
  │ (key => key !== 'parameters');\n" +
  │   '        let methods = lodash.difference(["get", "po
  │ st", "put", "delete"], validMethods);\n' +
  │   "        let validMethodsSorted = validMethods.sort(
  │ ).join(',');\n" +
  │   '\n' +
  │   '        lodash.forEach(methods, (method) => {\n' +
  │   '            method = method.toUpperCase();\n' +
  │   '\n' +
  │   '            pm.sendRequest({\n' +
  │   '                url: baseUrl + url,\n' +
  │   '                method: method,\n' +
  │   '                header: standardHeader\n' +
  │   '            }, function (err, response) {\n' +
  │   '                if (err) {\n' +
  │   '                    console.error("test_405 error:"
  │ , err);\n' +
  │   '                    return;\n' +
  │   '                }\n' +
  │   '                if (!response) {\n' +
  │   '                    console.warn("test_405 undefine
  │ d response for", method, url);\n' +
  │   '                    return;\n' +
  │   '                }\n' +
  │   '\n' +
  │   '                const responseCopy = JSON.parse(JSO
  │ N.stringify(response));\n' +
  │   '                const responseCode = responseCopy.c
  │ ode;\n' +
  │   '                const allowHeaderSorted = getAllowH
  │ eader(responseCopy.header);\n' +
  │   '\n' +
  │   '                const responseJson = (response && r
  │ esponse.text()) ? response.json() : null;\n' +
  │   '                const responseTitle = responseJson.
  │ title;\n' +
  │   '\n' +
  │   '                if (responseCode != 405) {\n' +
  │   "                    pm.test(pm.info.requestName + '
  │ : ' + method + ' ' + url, function () {\n" +
  │   '                        pm.expect(responseCode).to.
  │ equal(405);\n' +
  │   '                    });\n' +
  │   '                    return;\n' +
  │   '                }\n' +
  │   '\n' +
  │   "                pm.test(pm.info.requestName + ': ' 
  │ + method + ' ' + url, function () {\n" +
  │   '                    pm.expect(responseCode).to.equa
  │ l(405);\n' +
  │   '                    pm.expect(allowHeaderSorted).to
  │ .equal(validMethodsSorted);\n' +
  │   "                    pm.expect(responseTitle).to.equ
  │ al('Method Not Allowed');\n" +
  │   '                });\n' +
  │   '            });\n' +
  │   '        });\n' +
  │   '    });\n' +
  │   '}'
  │ 'function test_maxLength (pm, baseUrl, standardHeader,
  │  paths) {\n' +
  │   '    lodash.forEach(paths, (path, url) => {\n' +
  │   '        url = url.replace(/{[^}]+}/g, PRE_DEFINE_IN
  │ T_VALUE.toString());\n' +
  │   '        let methods = Object.keys(path)\n' +
  │   "            .filter(key => key !== 'parameters')\n"
  │  +
  │   "            .filter(method => method === 'post' || 
  │ method === 'put');\n" +
  │   '        let body = null;\n' +
  │   '        let schemaName = null;\n' +
  │   '        lodash.forEach(methods, (method) => {\n' +
  │   '\n' +
  │   '            schemaName = getRequestBodySchemaName(p
  │ ath, method, url);\n' +
  │   "            if (schemaName === '') {\n" +
  │   '                pm.test(`test_maxLength schemaName 
  │ not found`, () => {\n' +
  │   '                    pm.expect(schemaName).to.not.be
  │ .empty;\n' +
  │   '                });\n' +
  │   '                return;\n' +
  │   '            }\n' +
  │   '            //console.log(schemaName, path, method,
  │  url)\n' +
  │   '\n' +
  │   '            let tempReqBody;\n' +
  │   '            try {\n' +
  │   '                tempReqBody = utils.setInvalidMaxLe
  │ ngthRequestBody(schemaName);\n' +
  │   '            } catch (error) {\n' +
  │   '                console.warn(`test_maxLength Error 
  │ generating tempReqBody for schema: ${schemaName}`, err
  │ or);\n' +
  │   '                tempReqBody = {};\n' +
  │   '                pm.test(`test_maxLength Generate te
  │ mpReqBody for schema: ${schemaName}`, () => {\n' +
  │   '                    pm.expect(tempReqBody).to.not.b
  │ e.empty;\n' +
  │   '                });\n' +
  │   '            }\n' +
  │   '\n' +
  │   '            body = {\n' +
  │   "                mode: 'application/json',\n" +
  │   '                raw: JSON.stringify(tempReqBody)\n'
  │  +
  │   '            };\n' +
  │   '\n' +
  │   '            method = method.toUpperCase();\n' +
  │   '            pm.sendRequest({\n' +
  │   '                url: baseUrl + url,\n' +
  │   '                method: method,\n' +
  │   '                header: standardHeader,\n' +
  │   '                body\n' +
  │   '            }, function (err, response) {\n' +
  │   '                if (err) {\n' +
  │   '                    console.error("test_maxLength e
  │ rror:", err);\n' +
  │   '                    return;\n' +
  │   '                }\n' +
  │   '                if (!response) {\n' +
  │   '                    console.warn("test_maxLength un
  │ defined response for", method, url);\n' +
  │   '                    return;\n' +
  │   '                }\n' +
  │   '\n' +
  │   '                const responseCopy = JSON.parse(JSO
  │ N.stringify(response));\n' +
  │   '                const responseCode = responseCopy.c
  │ ode;\n' +
  │   '                const responseJson = (response && r
  │ esponse.text()) ? response.json() : null;\n' +
  │   '\n' +
  │   '                let reqBody = apiSchemas[schemaName
  │ ];\n' +
  │   '\n' +
  │   "                const expectedErrors = utils.getExp
  │ ectedInvalidSchemaErrors('invalidMaxLength', null, req
  │ Body, JSON.parse(body.raw));\n" +
  │   "                const expectedTitles = lodash.map(e
  │ xpectedErrors, (obj) => lodash.omit(obj, 'type'));\n" 
  │ +
  │   "                let actualTitles = lodash.map(respo
  │ nseJson.errors, (obj) => lodash.omit(obj, 'type'));\n"
  │  +
  │   '                actualTitles = lodash.map(actualTit
  │ les, (error) => {\n' +
  │   "                    error.title = lodash.replace(er
  │ ror.title, /^\\$?\\w*(\\[\\d+\\])?(\\.\\w+(\\[\\d+\\])
  │ ?)*\\./, '');\n" +
  │   '                    return error;\n' +
  │   '                });\n' +
  │   "                //console.log('test_maxLength'+ met
  │ hod + ' ' + url, actualTitles, expectedTitles)\n" +
  │   '\n' +
  │   '                // Sort expected and actual titles 
  │ alphabetically by title string\n' +
  │   "                const sortedActualTitles = lodash.o
  │ rderBy(actualTitles, ['title'], ['asc']);\n" +
  │   "                const sortedExpectedTitles = lodash
  │ .orderBy(expectedTitles, ['title'], ['asc']);\n" +
  │   '\n' +
  │   '\n' +
  │   '                // Check that all expected errors a
  │ re present (allow additional errors)\n' +
  │   '                const expectedTitleStrings = sorted
  │ ExpectedTitles.map(e => e.title);\n' +
  │   '                const actualTitleStrings = sortedAc
  │ tualTitles.map(e => e.title);\n' +
  │   '\n' +
  │   "                pm.test(pm.info.requestName + ': ' 
  │ + method + ' ' + url, function () {\n" +
  │   '                    pm.expect(responseCode).to.equa
  │ l(400);\n' +
  │   '\n' +
  │   '                    // Ensure we have at least the 
  │ minimum expected number of errors\n' +
  │   '                    pm.expect(actualTitleStrings.le
  │ ngth).to.be.at.least(expectedTitleStrings.length);\n' 
  │ +
  │   '                    \n' +
  │   '                    expectedTitleStrings.forEach(ex
  │ pectedTitle => {\n' +
  │   '                        pm.expect(actualTitleString
  │ s).to.include(expectedTitle, \n' +
  │   '                            `Expected error "${expe
  │ ctedTitle}" should be present in actual errors`);\n' +
  │   '                    });\n' +
  │   '                    \n' +
  │   '                    \n' +
  │   '                });\n' +
  │   '            });\n' +
  │   '        });\n' +
  │   '    });\n' +
  │   '}'
  │ 'function test_missingRequiredFields(pm, baseUrl, stan
  │ dardHeader, paths) {\n' +
  │   '    lodash.forEach(paths, (path, url) => {\n' +
  │   "        console.log('path:', path);\n" +
  │   '        url = url.replace(/{[^}]+}/g, PRE_DEFINE_IN
  │ T_VALUE.toString());\n' +
  │   '        let methods = Object.keys(path)\n' +
  │   "            .filter(key => key !== 'parameters')\n"
  │  +
  │   "            .filter(method => method === 'post' || 
  │ method === 'put');\n" +
  │   '        let body = null;\n' +
  │   '        let tempReqBody = null;\n' +
  │   '        lodash.forEach(methods, (method) => {\n' +
  │   '\n' +
  │   '            let schemaName = getRequestBodySchemaNa
  │ me(path, method, url);\n' +
  │   "            console.log('schemaName:', schemaName);
  │ \n" +
  │   "            if (schemaName === '') return;\n" +
  │   '\n' +
  │   '            try {\n' +
  │   '                tempReqBody = utils.setInvalidRequi
  │ redFieldRequestBody(schemaName);\n' +
  │   '            } catch (error) {\n' +
  │   '                console.warn(`test_missingRequiredF
  │ ields Error generating tempReqBody for schema: ${schem
  │ aName}`, error);\n' +
  │   '                tempReqBody = {};\n' +
  │   '                pm.test(`test_missingRequiredFields
  │  Generate tempReqBody for schema: ${schemaName}`, () =
  │ > {\n' +
  │   '                    pm.expect(tempReqBody).to.not.b
  │ e.empty;\n' +
  │   '                });\n' +
  │   '            }\n' +
  │   '\n' +
  │   '            if (lodash.isEmpty(tempReqBody)) {\n' +
  │   "                console.warn('No fields to test, sc
  │ hema(' + schemaName + '): ' + method + ' ' + url);\n" 
  │ +
  │   '                tempReqBody = {};\n' +
  │   '                return true;\n' +
  │   '            }\n' +
  │   '\n' +
  │   '            body = {\n' +
  │   "                mode: 'application/json',\n" +
  │   '                raw: JSON.stringify(tempReqBody)\n'
  │  +
  │   '            };\n' +
  │   '\n' +
  │   '            method = method.toUpperCase();\n' +
  │   '            pm.sendRequest({\n' +
  │   '                url: baseUrl + url,\n' +
  │   '                method: method,\n' +
  │   '                header: standardHeader,\n' +
  │   '                body\n' +
  │   '            }, function (err, response) {\n' +
  │   '                if (err) {\n' +
  │   '                    console.error("test_missingRequ
  │ iredFields error:", err);\n' +
  │   '                    return;\n' +
  │   '                }\n' +
  │   '                if (!response) {\n' +
  │   '                    console.warn("test_missingRequi
  │ redFields undefined response for", method, url);\n' +
  │   '                    return;\n' +
  │   '                }\n' +
  │   '\n' +
  │   '                const responseCopy = JSON.parse(JSO
  │ N.stringify(response));\n' +
  │   '                const responseCode = responseCopy.c
  │ ode;\n' +
  │   '                const responseJson = (response && r
  │ esponse.text()) ? response.json() : null;\n' +
  │   '\n' +
  │   '                const reqBody = utils.getRequestBod
  │ ySchema(method, url);\n' +
  │   "                //const expectedErrors = utils.getE
  │ xpectedInvalidSchemaErrors('missingRequired', null, re
  │ qBody, JSON.parse(body.raw));\n" +
  │   "                const expectedErrors = utils.getExp
  │ ectedInvalidSchemaErrors('missingRequired', null, reqB
  │ ody, tempReqBody);\n" +
  │   "                const expectedTitles = lodash.map(e
  │ xpectedErrors, (obj) => lodash.omit(obj, 'type'));\n" 
  │ +
  │   "                let actualTitles = lodash.map(respo
  │ nseJson.errors, (obj) => lodash.omit(obj, 'type'));\n"
  │  +
  │   '                actualTitles = lodash.map(actualTit
  │ les, (error) => {\n' +
  │   `                    error.title = lodash.replace(er
  │ ror.title, /^\\$\\./, ''); // Replace "$." at the star
  │ t of the string\n` +
  │   '                    return error;\n' +
  │   '                });\n' +
  │   "                //console.log('test_missingRequired
  │ Fields' + method + ' ' + url, actualTitles, expectedTi
  │ tles)\n" +
  │   '\n' +
  │   "                pm.test(pm.info.requestName + ': ' 
  │ + method + ' ' + url, function () {\n" +
  │   '                    pm.expect(responseCode).to.equa
  │ l(400);\n' +
  │   '                    pm.expect(actualTitles).to.have
  │ .deep.members(expectedTitles);\n' +
  │   '                });\n' +
  │   '            });\n' +
  │   '        });\n' +
  │   '    });\n' +
  │   '}'
  │ 'function test_invalidJsonObject(pm, baseUrl, standard
  │ Header, paths) {\n' +
  │   '    lodash.forEach(paths, (path, url) => {\n' +
  │   '\n' +
  │   '        url = url.replace(/{[^}]+}/g, PRE_DEFINE_IN
  │ T_VALUE.toString());\n' +
  │   '        if (!(filters.urlFilter(url))) { return; };
  │ \n' +
  │   '\n' +
  │   "        let methods = Object.keys(path).filter(key 
  │ => key !== 'parameters');\n" +
  │   '\n' +
  │   '        lodash.forEach(methods, (method) => {\n' +
  │   "            let errorCode = 'invalidJsonObject';\n"
  │  +
  │   "            let errorDesc = 'Request body is expect
  │ ed to be a valid JSON object.';\n" +
  │   "            if (method === 'post' || method === 'pu
  │ t') {\n" +
  │   '\n' +
  │   '                let schemaName = getRequestBodySche
  │ maName(path, method, url);\n' +
  │   "                if (schemaName === '') return;\n" +
  │   '                let reqBodySchema = apiSchemas[sche
  │ maName];\n' +
  │   "                const isArrayType = reqBodySchema &
  │ & reqBodySchema.type === 'array';\n" +
  │   "                const isObjectType = reqBodySchema 
  │ && reqBodySchema.type === 'object';\n" +
  │   '                let tempReqBody = null;\n' +
  │   '\n' +
  │   '\n' +
  │   '                if (isObjectType) {\n' +
  │   "                    errorCode = 'invalidJsonObject'
  │ ;\n" +
  │   "                    errorDesc = 'Request body is ex
  │ pected to be a valid JSON object.';\n" +
  │   '                } else if (isArrayType) {\n' +
  │   '                    return false;\n' +
  │   '                }\n' +
  │   '\n' +
  │   '                method = method.toUpperCase();\n' +
  │   '\n' +
  │   "                let skipRequest = lodash.find(utils
  │ .skipRequests, { test: 'invalidJsonObject', method, ur
  │ l });\n" +
  │   '\n' +
  │   '                if (skipRequest) {\n' +
  │   '                    return;\n' +
  │   '                }\n' +
  │   '\n' +
  │   '                pm.sendRequest(\n' +
  │   '                    {\n' +
  │   '                        url: baseUrl + url,\n' +
  │   '                        method: method,\n' +
  │   '                        body: {\n' +
  │   "                            mode: 'application/json
  │ ',\n" +
  │   '                            raw: tempReqBody\n' +
  │   '                        },\n' +
  │   '                        header: standardHeader\n' +
  │   '                    },\n' +
  │   '                    function (err, response) {\n' +
  │   '                        if (err || response.code !=
  │  400) {\n' +
  │   "                            pm.test(pm.info.request
  │ Name + ': ' + method + ' ' + url, function () {\n" +
  │   '                                pm.expect(response.
  │ code).to.equal(400);\n' +
  │   '                            });\n' +
  │   '                            return;\n' +
  │   '                        }\n' +
  │   '\n' +
  │   '                        let responseCode = response
  │ .code;\n' +
  │   '                        let responseJson = (respons
  │ e.text()) ? response.json() : {};\n' +
  │   '\n' +
  │   "                        pm.test(errorCode + ' respo
  │ nse ' + method + ' ' + url, function () {\n" +
  │   '                            try {\n' +
  │   '                                pm.expect(responseC
  │ ode).to.equal(400);\n' +
  │   '                                if (responseJson.er
  │ rors[0].code) {\n' +
  │   '                                    pm.expect(respo
  │ nseJson.errors[0].code).to.equal(errorCode);\n' +
  │   '                                }\n' +
  │   '\n' +
  │   '                                if (responseJson.er
  │ rors[0].description) {\n' +
  │   '                                    pm.expect(respo
  │ nseJson.errors[0].description).to.contain(errorDesc);\
  │ n' +
  │   '                                }\n' +
  │   '                                else if (responseJs
  │ on.errors[0].title) {\n' +
  │   '                                    pm.expect(respo
  │ nseJson.errors[0].title).to.contain(errorDesc);\n' +
  │   '                                }\n' +
  │   '                            }\n' +
  │   '                            catch (err) {\n' +
  │   '                                // debug\n' +
  │   '                                console.log(`${meth
  │ od}-${url}`)\n' +
  │   "                                console.log('reques
  │ t: ', tempReqBody)\n" +
  │   "                                console.log('respon
  │ se: ', responseJson)\n" +
  │   "                                console.log('expect
  │ ed: ', { code: errorCode })\n" +
  │   '                                throw new Error(err
  │ )\n' +
  │   '                            }\n' +
  │   '                        });\n' +
  │   '                    }\n' +
  │   '                );\n' +
  │   '\n' +
  │   '\n' +
  │   '            } else {\n' +
  │   '                return;\n' +
  │   '            }\n' +
  │   '\n' +
  │   '        });\n' +
  │   '    });\n' +
  │   '}'
  │ 'function test_invalidInteger(pm, baseUrl, standardHea
  │ der, paths) {\n' +
  │   '    lodash.forEach(paths, (path, url) => {\n' +
  │   '        // Replace path variables for URL filtering
  │  and logging\n' +
  │   '        let processedUrl = url.replace(/{[^}]+}/g, 
  │ PRE_DEFINE_INT_VALUE.toString());\n' +
  │   '\n' +
  │   "        //console.log('--- Processing URL:', url); 
  │ // Added log\n" +
  │   '\n' +
  │   '        if (!(filters.urlFilter(processedUrl))) {\n
  │ ' +
  │   "            console.warn('URL filtered out:', proce
  │ ssedUrl); // Added log\n" +
  │   '            return;\n' +
  │   '        }\n' +
  │   '\n' +
  │   "        let methods = Object.keys(path).filter(key 
  │ => (key == 'post' || key == 'put'));\n" +
  │   "        //console.log('Found methods for', processe
  │ dUrl, ':', methods); // Added log\n" +
  │   '\n' +
  │   '        if (lodash.isEmpty(methods)) {\n' +
  │   "            console.warn('No POST or PUT methods fo
  │ und for URL:', processedUrl); // Added log\n" +
  │   '        }\n' +
  │   '\n' +
  │   '        let body = null;\n' +
  │   '        lodash.forEach(methods, (method) => {\n' +
  │   "            //console.log('--- Attempting to test m
  │ ethod:', method.toUpperCase(), 'for URL:', processedUr
  │ l); // Added log\n" +
  │   '\n' +
  │   '            let skipRequest = lodash.find(utils.ski
  │ pRequests, { test: pm.info.requestName, method: method
  │ .toUpperCase(), url: processedUrl });\n' +
  │   '\n' +
  │   '            if (skipRequest) {\n' +
  │   "                console.warn('Skipping request due 
  │ to skipRequests config:', pm.info.requestName, method.
  │ toUpperCase(), processedUrl); // Added log\n" +
  │   '                return;\n' +
  │   '            }\n' +
  │   '\n' +
  │   '            let schemaName = getRequestBodySchemaNa
  │ me(path, method, url);\n' +
  │   "            //console.log('Determined schemaName fo
  │ r', processedUrl, method, ':', schemaName); // Added l
  │ og\n" +
  │   "            if (schemaName === '') {\n" +
  │   "                console.warn('Empty schemaName for'
  │ , processedUrl, method, '. Skipping test.'); // Added 
  │ log\n" +
  │   '                return;\n' +
  │   '            }\n' +
  │   '\n' +
  │   '            // This is the critical part - need to 
  │ ensure this function returns a body with integer field
  │ s\n' +
  │   '            let tempReqBody = utils.setInvalidInteg
  │ erRequestBody(schemaName);\n' +
  │   "            //console.log('Generated tempReqBody fo
  │ r schema', schemaName, ':', JSON.stringify(tempReqBody
  │ )); // Added log\n" +
  │   '\n' +
  │   '            if (lodash.isEmpty(tempReqBody)) {\n' +
  │   "                console.warn('No fields to test (te
  │ mpReqBody is empty) for: ' + processedUrl + ' with sch
  │ emaName: ' + schemaName);\n" +
  │   '                return;\n' +
  │   '            }\n' +
  │   '\n' +
  │   '            let obj = tempReqBody;\n' +
  │   '            if (Array.isArray(tempReqBody)) {\n' +
  │   '                obj = tempReqBody[0];\n' +
  │   '            }\n' +
  │   '\n' +
  │   '            // This commented block was a good thou
  │ ght, but its logic should ideally be inside setInvalid
  │ IntegerRequestBody\n' +
  │   '            // if (!lodash.some(obj, lodash.isNumbe
  │ r)) {\n' +
  │   "            //     //console.warn('No number fields
  │  to test: '+url, obj);\n" +
  │   '            //     //return false;\n' +
  │   '            // }\n' +
  │   '\n' +
  │   '            body = {\n' +
  │   "                mode: 'application/json',\n" +
  │   '                raw: JSON.stringify(tempReqBody)\n'
  │  +
  │   '            };\n' +
  │   '\n' +
  │   '            method = method.toUpperCase();\n' +
  │   '            pm.sendRequest({\n' +
  │   '                url: baseUrl + processedUrl,\n' +
  │   '                method: method,\n' +
  │   '                body: body,\n' +
  │   '                header: standardHeader\n' +
  │   '            }, function (err, response) {\n' +
  │   '                const responseCode = (response && r
  │ esponse.code) ? response.code : null;\n' +
  │   '                const responseJson = (response && r
  │ esponse.text()) ? response.json() : {};\n' +
  │   '\n' +
  │   "                //console.log('Response received fo
  │ r', method, processedUrl, 'Code:', responseCode, 'Erro
  │ rs:', JSON.stringify(responseJson.errors)); // Added l
  │ og\n" +
  │   '\n' +
  │   '                if (err || responseCode != 400) {\n
  │ ' +
  │   "                    pm.test(pm.info.requestName + '
  │ : ' + method + ' ' + processedUrl + ' (Expected 400 - 
  │ Failed or No Response)', function () { // More descrip
  │ tive test name\n" +
  │   '                        pm.expect(responseCode).to.
  │ equal(400);\n' +
  │   '                    });\n' +
  │   "                    console.error('Test FAILED or N
  │ O RESPONSE for:', method, processedUrl, 'Response Code
  │ :', responseCode, 'Error:', err); // Error log\n" +
  │   '                    return;\n' +
  │   '                }\n' +
  │   '\n' +
  │   '                const reqBody = utils.getRequestBod
  │ ySchema(method, url); // Using original URL for schema
  │  lookup\n' +
  │   "                const expectedErrors = utils.getExp
  │ ectedInvalidSchemaErrors('invalidInteger', null, reqBo
  │ dy, JSON.parse(body.raw));\n" +
  │   '\n' +
  │   "                pm.test(pm.info.requestName + ': ' 
  │ + method + ' ' + processedUrl + ' (Expected 400 - Pass
  │ ed)', function () { // More descriptive test name\n" +
  │   '                    pm.expect(responseCode).to.equa
  │ l(400);\n' +
  │   '                    pm.expect(utils.testIncludeErro
  │ rsArray(responseJson.errors, expectedErrors, true)).to
  │ .equal(true);\n' +
  │   '                });\n' +
  │   '            });\n' +
  │   '        });\n' +
  │   '    });\n' +
  │   '}'
  │ 'function test_invalidJsonArray(pm, baseUrl, standardH
  │ eader, paths) {\n' +
  │   '\n' +
  │   '    lodash.forEach(paths, (path, url) => {\n' +
  │   '        if (!(filters.urlFilter(url))) { return; }\
  │ n' +
  │   '\n' +
  │   '        let originalUrl = url; // Store original UR
  │ L for logging/debugging if needed\n' +
  │   '        url = url.replace(/{[^}]+}/g, PRE_DEFINE_IN
  │ T_VALUE.toString());\n' +
  │   '\n' +
  │   "        let methods = Object.keys(path).filter(key 
  │ => (key == 'post' || key == 'put'));\n" +
  │   '        lodash.forEach(methods, (method) => {\n' +
  │   '\n' +
  │   '            let schemaName = getRequestBodySchemaNa
  │ me(path, method, originalUrl); // Use originalUrl to g
  │ et schema\n' +
  │   "            if (schemaName === '') {\n" +
  │   "                // If no request body schema is def
  │ ined, we can't determine expected type.\n" +
  │   '                // You might choose to skip or appl
  │ y a generic invalid body test.\n' +
  │   "                // For this specific test (invalidJ
  │ sonArray), we'll skip if no schema is found.\n" +
  │   '                console.warn(`Skipping test for ${m
  │ ethod} ${url}: No request body schema defined.`);\n' +
  │   '                return;\n' +
  │   '            }\n' +
  │   '\n' +
  │   '            let reqBodySchema = apiSchemas[schemaNa
  │ me];\n' +
  │   '\n' +
  │   '            // Determine if the schema explicitly e
  │ xpects an array, object, or neither.\n' +
  │   '            // This allows for more targeted assert
  │ ions.\n' +
  │   "            const isArrayType = reqBodySchema && re
  │ qBodySchema.type === 'array';\n" +
  │   "            const isObjectType = reqBodySchema && r
  │ eqBodySchema.type === 'object';\n" +
  │   '\n' +
  │   '            // tempReqBody will be an empty object,
  │  which is "invalid" if an array is expected,\n' +
  │   '            // or if a specific object structure is
  │  expected (but not an empty one).\n' +
  │   '            let tempReqBody = {}; // Explicitly use
  │  an empty object.\n' +
  │   '\n' +
  │   '            method = method.toUpperCase();\n' +
  │   '            pm.sendRequest(\n' +
  │   '                {\n' +
  │   '                    url: baseUrl + url,\n' +
  │   '                    method: method,\n' +
  │   '                    body: {\n' +
  │   "                        mode: 'application/json',\n
  │ " +
  │   '                        raw: JSON.stringify(tempReq
  │ Body) // Stringify the JSON body\n' +
  │   '                    },\n' +
  │   '                    header: standardHeader\n' +
  │   '                },\n' +
  │   '                function (err, response) {\n' +
  │   '                    // Log errors or non-400 respon
  │ ses\n' +
  │   '                    if (err || response.code !== 40
  │ 0) {\n' +
  │   '                        console.warn(`Unexpected re
  │ sponse for ${method} ${url}: Code ${response.code}, Bo
  │ dy: ${response.text()}`);\n' +
  │   '                    }\n' +
  │   '\n' +
  │   '                    let responseCode = response.cod
  │ e;\n' +
  │   '                    let responseJson;\n' +
  │   '                    try {\n' +
  │   '                        responseJson = (response.te
  │ xt()) ? response.json() : {};\n' +
  │   '                    } catch (e) {\n' +
  │   '                        console.warn(`Failed to par
  │ se JSON response for ${method} ${url}: ${response.text
  │ ()}`, e);\n' +
  │   '                        responseJson = {}; // Set t
  │ o empty object if parsing fails\n' +
  │   '                    }\n' +
  │   '\n' +
  │   '                  pm.test(`${method} ${url} - Inval
  │ id JSON Array/Object`, function () {\n' +
  │   '                try {\n' +
  │   '                          pm.expect(responseCode).t
  │ o.equal(400);\n' +
  │   '\n' +
  │   '                         if (isArrayType) {\n' +
  │   '                            if (responseJson.errors
  │  && responseJson.errors.length > 0) {\n' +
  │   '                                 if (responseJson.e
  │ rrors[0].code) {\n' +
  │   "                                        pm.expect(r
  │ esponseJson.errors[0].code).to.equal('invalidJsonArray
  │ ');\n" +
  │   '                                         }\n' +
  │   '                                  if (responseJson.
  │ errors[0].description) {\n' +
  │   "                                     pm.expect(resp
  │ onseJson.errors[0].description).to.contain('Request bo
  │ dy is expected to be a valid JSON array.');\n" +
  │   '                                                   
  │           } else if (responseJson.errors[0].title) {\n
  │ ' +
  │   "                                                   
  │  pm.expect(responseJson.errors[0].title).to.contain('R
  │ equest body is expected to be a valid JSON array.');\n
  │ " +
  │   '                                                   
  │          }\n' +
  │   '                                                 } 
  │ else {\n' +
  │   "                                           pm.expec
  │ t(true, 'Response should contain errors array for arra
  │ y type validation').to.be.true;\n" +
  │   '                                                   
  │              }\n' +
  │   '                                                   
  │                      } else { \n' +
  │   '                                     if (responseJs
  │ on.errors && responseJson.errors.length > 0) {\n' +
  │   '                                const errorMessage 
  │ = responseJson.errors[0].description || responseJson.e
  │ rrors[0].title;\n' +
  │   '                pm.expect(errorMessage).to.match(/R
  │ equest body is expected to be a valid JSON object|Miss
  │ ing required properties|No valid fields sent|is a requ
  │ ired field|is required/i);\n' +
  │   '\n' +
  │   '            } else {\n' +
  │   "                pm.expect(true, 'Response should co
  │ ntain errors array for invalid body').to.be.true;\n" +
  │   '            }\n' +
  │   '        }\n' +
  │   '    } catch (err) {\n' +
  │   '        console.log(`Test Failed: ${method}-${url}`
  │ );\n' +
  │   "        console.log('Request body sent: ', tempReqB
  │ ody);\n" +
  │   "        console.log('Response code: ', responseCode
  │ );\n" +
  │   "        console.log('Response JSON: ', responseJson
  │ );\n" +
  │   '        throw new Error(err);\n' +
  │   '    }\n' +
  │   '});\n' +
  │   '                }\n' +
  │   '            );\n' +
  │   '        });\n' +
  │   '    });\n' +
  │   '}'
  │ 'function test_noValidFields(pm, baseUrl, standardHead
  │ er, paths) {\n' +
  │   '    lodash.forEach(paths, (path, url) => {\n' +
  │   '        url = url.replace(/{[^}]+}/g, PRE_DEFINE_IN
  │ T_VALUE.toString());\n' +
  │   "        //if(url != '/clients/-9/aChargeCodes'){ re
  │ turn; }\n" +
  │   '        let methods = Object.keys(path)\n' +
  │   "            .filter(key => key !== 'parameters')\n"
  │  +
  │   "            .filter(method => method === 'post' || 
  │ method === 'put');\n" +
  │   '        let body = null;\n' +
  │   '        let tempReqBody = null;\n' +
  │   '        lodash.forEach(methods, (method) => {\n' +
  │   "            let errorCode = 'noValidFields';\n" +
  │   "            let errorDesc = 'No valid fields sent w
  │ ith the request. Please refer to the OpenAPI Specifica
  │ tion for a list of supported fields.';\n" +
  │   '\n' +
  │   '\n' +
  │   '            let schemaName = getRequestBodySchemaNa
  │ me(path, method, url);\n' +
  │   "            if (schemaName === '') return;\n" +
  │   '            let reqBodySchema = apiSchemas[schemaNa
  │ me];\n' +
  │   '\n' +
  │   '\n' +
  │   '            // try {\n' +
  │   '            //     reqBodySchema = utils.getRequest
  │ BodySchema(method, url);\n' +
  │   '            // } catch (error) {\n' +
  │   '            //     console.warn(`Error getting getR
  │ equestBodySchema for ${method} ${url}`, error);\n' +
  │   '            //     return;\n' +
  │   '            // }\n' +
  │   '\n' +
  │   '\n' +
  │   "            const isArrayType = reqBodySchema && re
  │ qBodySchema.type === 'array';\n" +
  │   "            const isObjectType = reqBodySchema && r
  │ eqBodySchema.type === 'object';\n" +
  │   '            if (isArrayType) {\n' +
  │   "                tempReqBody = '[]';\n" +
  │   '            } else if (isObjectType) {\n' +
  │   '                // no required fields, otherwise it
  │  will have missing required fields error \n' +
  │   '                if ((reqBodySchema.required || []).
  │ length === 0)\n' +
  │   "                    tempReqBody = '{}';\n" +
  │   '            } else {\n' +
  │   "                console.warn(pm.info.requestName + 
  │ 'Skipping: ' + method + ' ' + url, reqBodySchema);\n" 
  │ +
  │   '                return;\n' +
  │   '            }\n' +
  │   "            //console.log('reqBodySchema', reqBodyS
  │ chema.items.required);\n" +
  │   '            if (reqBodySchema && reqBodySchema.item
  │ s && reqBodySchema.items.required && reqBodySchema.ite
  │ ms.required.length > 0) {\n' +
  │   "                errorCode = 'missingRequiredField';
  │ \n" +
  │   "                errorDesc = 'is a required field';\
  │ n" +
  │   '            }\n' +
  │   '            method = method.toUpperCase();\n' +
  │   '\n' +
  │   '            body = {\n' +
  │   "                mode: 'application/json',\n" +
  │   '                raw: JSON.stringify(tempReqBody)\n'
  │  +
  │   '            };\n' +
  │   '            pm.sendRequest(\n' +
  │   '                {\n' +
  │   '                    url: baseUrl + url,\n' +
  │   '                    method: method,\n' +
  │   '                    body,\n' +
  │   '                    header: standardHeader\n' +
  │   '                },\n' +
  │   '                function (err, response) {\n' +
  │   '                    const responseCode = (response 
  │ && response.code) ? response.code : null;\n' +
  │   '                    const responseJson = (response 
  │ && response.text()) ? response.json() : {};\n' +
  │   '\n' +
  │   '                    if (err || responseCode != 400)
  │  {\n' +
  │   "                        //console.error('Response:'
  │  + response.text(), response);\n" +
  │   "                        pm.test(pm.info.requestName
  │  + ': ' + method + ' ' + url, function () {\n" +
  │   '                            pm.expect(responseCode)
  │ .to.equal(400);\n' +
  │   '                        });\n' +
  │   '                        return;\n' +
  │   '                    }\n' +
  │   '\n' +
  │   '                    // --- START: ADDED CODE HERE -
  │ --\n' +
  │   "                    let actualTitles = lodash.map(r
  │ esponseJson.errors, (obj) => lodash.omit(obj, 'type'))
  │ ;\n" +
  │   '                    actualTitles = lodash.map(actua
  │ lTitles, (error) => {\n' +
  │   '                        // This regex removes the J
  │ SON path prefix from the title (e.g., "$[0].fieldName.
  │ ")\n' +
  │   "                        error.title = lodash.replac
  │ e(error.title, /^\\$?\\w*(\\[\\d+\\])?(\\.\\w+(\\[\\d+
  │ \\])?)*\\./, ''); \n" +
  │   '                        return error;\n' +
  │   '                    });\n' +
  │   '                    // --- END: ADDED CODE HERE ---
  │ \n' +
  │   '\n' +
  │   "                    pm.test(pm.info.requestName + '
  │ : ' + method + ' ' + url, function () {\n" +
  │   '                        pm.expect(responseCode).to.
  │ equal(400);\n' +
  │   '                        //pm.expect(responseJson.er
  │ rors[0].code).to.equal(errorCode);\n' +
  │   '                        //pm.expect(responseJson.er
  │ rors[0].description).to.contain(errorDesc);\n' +
  │   '                    });\n' +
  │   '                }\n' +
  │   '            );\n' +
  │   '        });\n' +
  │   '    });\n' +
  │   '}'
  │ 'function test_belowMinValue(pm, baseUrl, standardHead
  │ er, paths) {\n' +
  │   '    lodash.forEach(paths, (path, url) => {\n' +
  │   "        //if(url != '/clients'){ return; }\n" +
  │   '        url = url.replace(/{[^}]+}/g, PRE_DEFINE_IN
  │ T_VALUE.toString());\n' +
  │   '        let methods = Object.keys(path)\n' +
  │   "            .filter(key => key !== 'parameters')\n"
  │  +
  │   "            .filter(method => method === 'post' || 
  │ method === 'put');\n" +
  │   '\n' +
  │   '        lodash.forEach(methods, (method) => {\n' +
  │   '            let body = null;\n' +
  │   '\n' +
  │   '            let schemaName = getRequestBodySchemaNa
  │ me(path, method, url);\n' +
  │   "            if (schemaName === '') return;\n" +
  │   '            let tempReqBody = utils.setNumberBelowM
  │ inValueRequestBody(apiSchemas[schemaName]);\n' +
  │   '            //console.log(url+" tempReqBody", tempR
  │ eqBody);\n' +
  │   '\n' +
  │   '            if (lodash.isEmpty(tempReqBody)) {\n' +
  │   "                //console.warn('No fields to test: 
  │ ' + url);\n" +
  │   '                return;\n' +
  │   '            }\n' +
  │   '\n' +
  │   '            body = {\n' +
  │   "                mode: 'application/json',\n" +
  │   '                raw: JSON.stringify(tempReqBody)\n'
  │  +
  │   '            };\n' +
  │   '\n' +
  │   '            method = method.toUpperCase();\n' +
  │   '            pm.sendRequest({\n' +
  │   '                url: baseUrl + url,\n' +
  │   '                method: method,\n' +
  │   '                body: body,\n' +
  │   '                header: standardHeader\n' +
  │   '            },\n' +
  │   '                function (err, response) {\n' +
  │   '                    if (err) {\n' +
  │   '                        console.error(pm.info.reque
  │ stName +" error:", err);\n' +
  │   '                        return;\n' +
  │   '                    }\n' +
  │   '                    if (!response) {\n' +
  │   '                        console.warn(pm.info.reques
  │ tName +" undefined response for", method, url);\n' +
  │   '                        return;\n' +
  │   '                    }\n' +
  │   '\n' +
  │   '                    const expectedErrorTitle = "can
  │ not be less than the minimum value of";\n' +
  │   '                    const responseCopy = JSON.parse
  │ (JSON.stringify(response));\n' +
  │   '                    const responseCode = responseCo
  │ py.code;\n' +
  │   '                    const responseJson = (response 
  │ && response.text()) ? response.json() : null;\n' +
  │   '                    const responseErrors = response
  │ Json.errors;\n' +
  │   '\n' +
  │   "                    pm.test(pm.info.requestName + '
  │ : ' + method + ' ' + url, function () {\n" +
  │   '                        pm.expect(responseCode).to.
  │ equal(400);\n' +
  │   '                        pm.expect(responseJson.erro
  │ rs[0].title).to.contain(expectedErrorTitle);\n' +
  │   '                    });\n' +
  │   '                });\n' +
  │   '        });\n' +
  │   '    });\n' +
  │   '}'
  │ 'function test_invalidString(pm, baseUrl, standardHead
  │ er, paths) {\n' +
  │   '    lodash.forEach(paths, (path, url) => {\n' +
  │   '        url = url.replace(/{[^}]+}/g, PRE_DEFINE_IN
  │ T_VALUE.toString());\n' +
  │   '        let methods = Object.keys(path)\n' +
  │   "            .filter(key => key !== 'parameters')\n"
  │  +
  │   "            .filter(method => method === 'post' || 
  │ method === 'put');\n" +
  │   '        let body = null;\n' +
  │   '        let schemaName = null;\n' +
  │   '        lodash.forEach(methods, (method) => {\n' +
  │   '\n' +
  │   '            schemaName = getRequestBodySchemaName(p
  │ ath, method, url);\n' +
  │   "            if (schemaName === '') {\n" +
  │   '                pm.test(`test_maxLength schemaName 
  │ not found`, () => {\n' +
  │   '                    pm.expect(schemaName).to.not.be
  │ .empty;\n' +
  │   '                });\n' +
  │   '                return;\n' +
  │   '            }\n' +
  │   '\n' +
  │   '            //console.log(schemaName, path, method,
  │  url)\n' +
  │   '\n' +
  │   '            let tempReqBody;\n' +
  │   '            try {\n' +
  │   '                tempReqBody = utils.setInvalidStrin
  │ gRequestBody(apiSchemas[schemaName]);\n' +
  │   '            } catch (error) {\n' +
  │   '                console.warn(`test_invalidString Er
  │ ror generating tempReqBody for schema: ${schemaName}`,
  │  error);\n' +
  │   '                tempReqBody = {};\n' +
  │   '                pm.test(`test_invalidString Generat
  │ e tempReqBody for schema: ${schemaName}`, () => {\n' +
  │   '                    pm.expect(tempReqBody).to.not.b
  │ e.empty;\n' +
  │   '                });\n' +
  │   '            }\n' +
  │   '\n' +
  │   '            body = {\n' +
  │   "                mode: 'application/json',\n" +
  │   '                raw: JSON.stringify(tempReqBody)\n'
  │  +
  │   '            };\n' +
  │   '\n' +
  │   '            method = method.toUpperCase();\n' +
  │   '            pm.sendRequest({\n' +
  │   '                url: baseUrl + url,\n' +
  │   '                method: method,\n' +
  │   '                header: standardHeader,\n' +
  │   '                body\n' +
  │   '            }, function (err, response) {\n' +
  │   '                if (err) {\n' +
  │   '                    console.error("test_invalidStri
  │ ng error:", err);\n' +
  │   '                    return;\n' +
  │   '                }\n' +
  │   '                if (!response) {\n' +
  │   '                    console.warn("test_invalidStrin
  │ g undefined response for", method, url);\n' +
  │   '                    return;\n' +
  │   '                }\n' +
  │   '\n' +
  │   '                const responseCopy = JSON.parse(JSO
  │ N.stringify(response));\n' +
  │   '                const responseCode = responseCopy.c
  │ ode;\n' +
  │   '                const responseJson = (response && r
  │ esponse.text()) ? response.json() : null;\n' +
  │   '\n' +
  │   '                let reqBody = apiSchemas[schemaName
  │ ];\n' +
  │   '\n' +
  │   "                const expectedErrors = utils.getExp
  │ ectedInvalidSchemaErrors('invalidString', null, reqBod
  │ y, JSON.parse(body.raw));\n" +
  │   "                const expectedTitles = lodash.map(e
  │ xpectedErrors, (obj) => lodash.omit(obj, 'type'));\n" 
  │ +
  │   "                let actualTitles = lodash.map(respo
  │ nseJson.errors, (obj) => lodash.omit(obj, 'type'));\n"
  │  +
  │   '                actualTitles = lodash.map(actualTit
  │ les, (error) => {\n' +
  │   "                    error.title = lodash.replace(er
  │ ror.title, /^\\$?\\w*(\\[\\d+\\])?(\\.\\w+(\\[\\d+\\])
  │ ?)*\\./, '');\n" +
  │   '                    return error;\n' +
  │   '                });\n' +
  │   '\n' +
  │   "                pm.test(pm.info.requestName + ': ' 
  │ + method + ' ' + url, function () {\n" +
  │   '                    pm.expect(responseCode).to.equa
  │ l(400);\n' +
  │   '\n' +
  │   '                    // Sort expected and actual tit
  │ les alphabetically by title string\n' +
  │   "                    const sortedActualTitles = loda
  │ sh.orderBy(actualTitles, ['title'], ['asc']);\n" +
  │   "                    const sortedExpectedTitles = lo
  │ dash.orderBy(expectedTitles, ['title'], ['asc']);\n" +
  │   '\n' +
  │   '\n' +
  │   '                    // Check that all expected erro
  │ rs are present (allow additional errors)\n' +
  │   '                    const expectedTitleStrings = so
  │ rtedExpectedTitles.map(e => e.title);\n' +
  │   '                    const actualTitleStrings = sort
  │ edActualTitles.map(e => e.title);\n' +
  │   '                    \n' +
  │   '                    expectedTitleStrings.forEach(ex
  │ pectedTitle => {\n' +
  │   '                        pm.expect(actualTitleString
  │ s).to.include(expectedTitle, \n' +
  │   '                            `Expected error "${expe
  │ ctedTitle}" should be present in actual errors`);\n' +
  │   '                    });\n' +
  │   '                    \n' +
  │   '                    // Ensure we have at least the 
  │ minimum expected number of errors\n' +
  │   '                    pm.expect(actualTitleStrings.le
  │ ngth).to.be.at.least(expectedTitleStrings.length, \n' 
  │ +
  │   '                        `Should have at least ${exp
  │ ectedTitleStrings.length} validation errors`);\n' +
  │   '                });\n' +
  │   '            });\n' +
  │   '        });\n' +
  │   '    });\n' +
  │   '}'
  │ 'function test_invalidDouble(pm, baseUrl, standardHead
  │ er, paths) {\n' +
  │   '    lodash.forEach(paths, (path, url) => {\n' +
  │   "        //if(url != '/clients'){ return; }\n" +
  │   '        url = url.replace(/{[^}]+}/g, PRE_DEFINE_IN
  │ T_VALUE.toString());\n' +
  │   '\n' +
  │   '        let methods = Object.keys(path)\n' +
  │   "            .filter(key => key !== 'parameters')\n"
  │  +
  │   "            .filter(method => method === 'post' || 
  │ method === 'put');\n" +
  │   '\n' +
  │   '        lodash.forEach(methods, (method) => {\n' +
  │   '\n' +
  │   '            let schemaName = getRequestBodySchemaNa
  │ me(path, method, url);\n' +
  │   "            if (schemaName === '') return;\n" +
  │   '            let tempReqBody = utils.setInvalidDoubl
  │ eRequestBody(apiSchemas[schemaName]);\n' +
  │   '\n' +
  │   '            if (lodash.isEmpty(tempReqBody)) {\n' +
  │   "                console.warn(pm.info.requestName + 
  │ ' No fields to test: ' + url);\n" +
  │   '                return;\n' +
  │   '            }\n' +
  │   '\n' +
  │   '            let obj = tempReqBody;\n' +
  │   '            if (Array.isArray(tempReqBody)) {\n' +
  │   '                obj = tempReqBody[0]\n' +
  │   '            }\n' +
  │   '\n' +
  │   '            if (!lodash.some(obj, lodash.isNumber))
  │  {\n' +
  │   "                //console.warn('No number fields to
  │  test: '+url, obj);\n" +
  │   '                //return false;\n' +
  │   '            }\n' +
  │   '\n' +
  │   '            /*\n' +
  │   '            if(Array.isArray(tempReqBody)){\n' +
  │   '                tempReqBody = [];\n' +
  │   "            }else if(typeof(tempReqBody) == 'object
  │ '){\n" +
  │   '                tempReqBody = {};\n' +
  │   '            }*/\n' +
  │   '\n' +
  │   '\n' +
  │   '            method = method.toUpperCase();\n' +
  │   '            pm.sendRequest({\n' +
  │   '                url: baseUrl + url,\n' +
  │   '                method: method,\n' +
  │   '                body: {\n' +
  │   "                    mode: 'application/json',\n" +
  │   '                    raw: JSON.stringify(tempReqBody
  │ )\n' +
  │   '                },\n' +
  │   '                header: standardHeader\n' +
  │   '            },\n' +
  │   '                function (err, response) {\n' +
  │   '                    const responseCode = (response 
  │ && response.code) ? response.code : null;\n' +
  │   '                    const responseJson = (response 
  │ && response.text()) ? response.json() : {};\n' +
  │   '\n' +
  │   '                    if (err || responseCode != 400)
  │  {\n' +
  │   "                        //console.error('Response:'
  │  + response.text(), response);\n" +
  │   "                        pm.test(pm.info.requestName
  │  + ': ' + method + ' ' + url, function () {\n" +
  │   '                            pm.expect(responseCode)
  │ .to.equal(400);\n' +
  │   '                        });\n' +
  │   '                        return;\n' +
  │   '                    }\n' +
  │   '\n' +
  │   '                    //const reqBody = utils.getRequ
  │ estBodySchema(method, url)\n' +
  │   "                    //const expectedErrors = utils.
  │ getExpectedInvalidSchemaErrors('invalidDouble', null, 
  │ reqBody, JSON.parse(body.raw));\n" +
  │   "                    //pm.test('invalidDouble respon
  │ se ' + method + ' ' + url + ` (expected errors length:
  │  ${expectedErrors.length}|actual errors length: ${resp
  │ onseJson.errors.length})`, function () {\n" +
  │   "                    pm.test(pm.info.requestName + '
  │ : ' + method + ' ' + url, function () {\n" +
  │   '                        pm.expect(responseCode).to.
  │ equal(400);\n' +
  │   '                        //pm.expect(utils.testInclu
  │ deErrorsArray(responseJson.errors, expectedErrors, tru
  │ e)).to.equal(true);\n' +
  │   '                    });\n' +
  │   '\n' +
  │   '                });\n' +
  │   '        });\n' +
  │   '    });\n' +
  │   '}'
  │ 'function test_invalidDateTime(pm, baseUrl, standardHe
  │ ader, paths) {\n' +
  │   '    lodash.forEach(paths, (path, url) => {\n' +
  │   '        url = url.replace(/{[^}]+}/g, PRE_DEFINE_IN
  │ T_VALUE.toString());\n' +
  │   '\n' +
  │   '        let methods = Object.keys(path)\n' +
  │   "            .filter(key => key !== 'parameters')\n"
  │  +
  │   "            .filter(method => method === 'post' || 
  │ method === 'put');\n" +
  │   '\n' +
  │   '        lodash.forEach(methods, (method) => {\n' +
  │   '\n' +
  │   '            let schemaName = getRequestBodySchemaNa
  │ me(path, method, url);\n' +
  │   "            if (schemaName === '') return;\n" +
  │   "            console.log('--------------------------
  │ --', apiSchemas[schemaName])\n" +
  │   '            let tempReqBody = utils.setInvalidTimes
  │ tampRequestBody(apiSchemas[schemaName], {}, {\n' +
  │   "                invalidTypes: ['invalidDateTime']\n
  │ " +
  │   '            });\n' +
  │   '\n' +
  │   '            if (lodash.isEmpty(tempReqBody)) {\n' +
  │   "                console.warn(pm.info.requestName + 
  │ ' No fields to test: ' + url);\n" +
  │   '                return;\n' +
  │   '            }\n' +
  │   '\n' +
  │   '            method = method.toUpperCase();\n' +
  │   '            pm.sendRequest({\n' +
  │   '                url: baseUrl + url,\n' +
  │   '                method: method,\n' +
  │   '                body: {\n' +
  │   "                    mode: 'application/json',\n" +
  │   '                    raw: JSON.stringify(tempReqBody
  │ )\n' +
  │   '                },\n' +
  │   '                header: standardHeader\n' +
  │   '            },\n' +
  │   '                function (err, response) {\n' +
  │   '                    const responseCode = (response 
  │ && response.code) ? response.code : null;\n' +
  │   '                    const responseJson = (response 
  │ && response.text()) ? response.json() : {};\n' +
  │   '\n' +
  │   '                    if (err || responseCode != 400)
  │  {\n' +
  │   "                        pm.test(pm.info.requestName
  │  + ': ' + method + ' ' + url, function () {\n" +
  │   '                            pm.expect(responseCode)
  │ .to.equal(400);\n' +
  │   '                        });\n' +
  │   '                        return;\n' +
  │   '                    }\n' +
  │   '\n' +
  │   "                    pm.test(pm.info.requestName + '
  │ : ' + method + ' ' + url, function () {\n" +
  │   '                        pm.expect(responseCode).to.
  │ equal(400);\n' +
  │   '                        //pm.expect(utils.testInclu
  │ deErrorsArray(responseJson.errors, expectedErrors, tru
  │ e)).to.equal(true);\n' +
  │   '                    });\n' +
  │   '                });\n' +
  │   '        });\n' +
  │   '    });\n' +
  │   '}'
  │ 'function test_invalidEnum(pm, baseUrl, standardHeader
  │ , paths) {\n' +
  │   '    lodash.forEach(paths, (path, url) => {\n' +
  │   "        //if(url != '/clients'){ return; }\n" +
  │   "        //if(url != '/aChargeCodes'){ return; }\n" 
  │ +
  │   '        url = url.replace(/{[^}]+}/g, PRE_DEFINE_IN
  │ T_VALUE.toString());\n' +
  │   '\n' +
  │   "        let methods = Object.keys(path).filter(key 
  │ => (key == 'post' || key == 'put'));\n" +
  │   '    \n' +
  │   '        lodash.forEach(methods, (method) => {\n' +
  │   '            let body = null;\n' +
  │   '\n' +
  │   '            let schemaName = getRequestBodySchemaNa
  │ me(path, method, url);\n' +
  │   "            if (schemaName === '') return;\n" +
  │   '            //console.log(url+"schemaName", schemaN
  │ ame);\n' +
  │   '            let tempReqBody = utils.setInvalidEnumR
  │ equestBody(apiSchemas[schemaName]);\n' +
  │   '            //console.log(url + " tempReqBody", tem
  │ pReqBody);\n' +
  │   '\n' +
  │   '            if (lodash.isEmpty(tempReqBody)) {\n' +
  │   "                console.warn('No fields to test: ' 
  │ + url);\n" +
  │   '                return;\n' +
  │   '            }\n' +
  │   '\n' +
  │   '            let obj = tempReqBody;\n' +
  │   '            if (Array.isArray(tempReqBody)) {\n' +
  │   '                obj = tempReqBody[0]\n' +
  │   '            }\n' +
  │   '\n' +
  │   '            if (!lodash.some(obj, lodash.isNumber))
  │  {\n' +
  │   "                //console.warn('No number fields to
  │  test: '+url, obj);\n" +
  │   '                //return false;\n' +
  │   '            }\n' +
  │   '\n' +
  │   '            /*\n' +
  │   '            if(Array.isArray(tempReqBody)){\n' +
  │   '                tempReqBody = [];\n' +
  │   "            }else if(typeof(tempReqBody) == 'object
  │ '){\n" +
  │   '                tempReqBody = {};\n' +
  │   '            }*/\n' +
  │   '\n' +
  │   '            body = {\n' +
  │   "                mode: 'application/json',\n" +
  │   '                raw: JSON.stringify(tempReqBody)\n'
  │  +
  │   '            };\n' +
  │   '\n' +
  │   '            method = method.toUpperCase();\n' +
  │   '\n' +
  │   '            pm.sendRequest(\n' +
  │   '                {\n' +
  │   '                    url: baseUrl + url,\n' +
  │   '                    method: method,\n' +
  │   '                    body: body,\n' +
  │   '                    header: standardHeader\n' +
  │   '                },\n' +
  │   '                function (err, response) {\n' +
  │   '                    if (err || response.code != 400
  │ ) {\n' +
  │   "                        console.warn('Response:' + 
  │ response.text(), response);\n" +
  │   '                        //throw new Error("An error
  │  has occurred. Check logs.");\n' +
  │   '                    }\n' +
  │   '\n' +
  │   '                    let responseCode = response.cod
  │ e;\n' +
  │   '                    let responseJson = (response.te
  │ xt()) ? response.json() : {};\n' +
  │   '                    const reqBody = utils.getReques
  │ tBodySchema(method, url);\n' +
  │   "                    const expectedErrors = utils.ge
  │ tExpectedInvalidSchemaErrors('invalidEnum', null, reqB
  │ ody, JSON.parse(body.raw));\n" +
  │   '                    console.log(expectedErrors)\n' 
  │ +
  │   "                    pm.test('invalidEnum response '
  │  + method + ' ' + url + ` (expected errors length: ${e
  │ xpectedErrors.length}|actual errors length: ${response
  │ Json.errors.length})`, function () {\n" +
  │   '                        pm.expect(responseCode).to.
  │ equal(400);\n' +
  │   '                        pm.expect(utils.testInclude
  │ ErrorsArray(responseJson.errors, expectedErrors, true)
  │ ).to.equal(true);\n' +
  │   '                    });\n' +
  │   "                    // pm.test('invalidEnum respons
  │ e ' + method + ' ' + url, function () {\n" +
  │   '                    //     pm.expect(responseCode).
  │ to.equal(400);\n' +
  │   "                    //     pm.expect(responseJson.e
  │ rrors[0].code).to.equal('invalidEnum');\n" +
  │   "                    //     pm.expect(responseJson.e
  │ rrors[0].description).to.contain('is expected to be a 
  │ value of [');\n" +
  │   '                    // });\n' +
  │   '                }\n' +
  │   '            );\n' +
  │   '        });\n' +
  │   '    });\n' +
  │   '}'
  │ 'function test_invalidIntPathParam(pm, baseUrl, standa
  │ rdHeader, paths) {\n' +
  │   '\n' +
  │   '    function sendRequestAndTest(params, path, url) 
  │ {\n' +
  │   "        let intParameters = lodash.filter(path.para
  │ meters, { 'schema': { 'type': 'integer' } });\n" +
  │   '        if (intParameters.length < 1) { return; }\n
  │ ' +
  │   '\n' +
  │   "        //if(!url.startsWith('/trips')){ return; }\
  │ n" +
  │   '\n' +
  │   "        url = url.replace(/{[^}]+}/g, 'ABC');\n" +
  │   "        let methods = Object.keys(path).filter(key 
  │ => key !== 'parameters');\n" +
  │   '        lodash.forEach(methods, (method) => {\n' +
  │   '            method = method.toUpperCase();\n' +
  │   '            pm.sendRequest\n' +
  │   '                (\n' +
  │   '                    {\n' +
  │   '                        url: baseUrl + url,\n' +
  │   '                        method: method,\n' +
  │   '                        header: standardHeader\n' +
  │   '                    },\n' +
  │   '                    function (err, response) {\n' +
  │   '                        if (err || response.code !=
  │  400) {\n' +
  │   "                            console.error('Response
  │ :' + response.text(), response);\n" +
  │   '                        }\n' +
  │   '\n' +
  │   '                        let responseCode = response
  │ .code;\n' +
  │   '                        let responseJson = (respons
  │ e.text()) ? response.json() : {};\n' +
  │   '\n' +
  │   "                        pm.test('invalidInteger pat
  │ h validation ' + method + ' ' + url, function () {\n" 
  │ +
  │   '                            pm.expect(responseCode)
  │ .to.equal(400);\n' +
  │   "                            pm.expect(responseJson.
  │ errors[0].code).to.equal('invalidInteger');\n" +
  │   '                            pm.expect(responseJson.
  │ errors[0].description).to.contain("is expected to be a
  │  valid integer.");\n' +
  │   '                        });\n' +
  │   '                    }\n' +
  │   '                );\n' +
  │   '        });\n' +
  │   '    }\n' +
  │   '\n' +
  │   '    lodash.forEach(paths, (path, url) => {\n' +
  │   '        if (path.parameters) {\n' +
  │   '            sendRequestAndTest(path.parameters, pat
  │ h, url);\n' +
  │   '        } else {\n' +
  │   '            lodash.forEach(path, (operation, method
  │ ) => {\n' +
  │   '                if (!operation.parameters) { return
  │ ; }\n' +
  │   '                sendRequestAndTest(operation.parame
  │ ters, path, url);\n' +
  │   '            })\n' +
  │   '        }\n' +
  │   '    });\n' +
  │   '}'
  │ 'function test_invalidMaxLengthPathParam(pm, baseUrl, 
  │ standardHeader, paths) {\n' +
  │   '    lodash.forEach(paths, (path, url) => {\n' +
  │   '        url = url.replace(/{[^}]+}/g, PRE_DEFINE_IN
  │ T_VALUE.toString());\n' +
  │   '        let methods = Object.keys(path)\n' +
  │   "            .filter(key => key !== 'parameters')\n"
  │  +
  │   "            .filter(method => method === 'post' || 
  │ method === 'put');\n" +
  │   '        let body = null;\n' +
  │   '        let schemaName = null;\n' +
  │   '        lodash.forEach(methods, (method) => {\n' +
  │   '\n' +
  │   '            schemaName = getRequestBodySchemaName(p
  │ ath, method, url);\n' +
  │   "            if (schemaName === '') {\n" +
  │   '                pm.test(`test_invalidMaxLengthPathP
  │ aram schemaName not found`, () => {\n' +
  │   '                    pm.expect(schemaName).to.not.be
  │ .empty;\n' +
  │   '                });\n' +
  │   '                return;\n' +
  │   '            }\n' +
  │   '            //console.log(schemaName, path, method,
  │  url)\n' +
  │   '\n' +
  │   '            let tempReqBody;\n' +
  │   '            try {\n' +
  │   '                tempReqBody = utils.setInvalidMaxLe
  │ ngthRequestBody(schemaName);\n' +
  │   '            } catch (error) {\n' +
  │   '                console.warn(`test_invalidMaxLength
  │ PathParam Error generating tempReqBody for schema: ${s
  │ chemaName}`, error);\n' +
  │   '                tempReqBody = {};\n' +
  │   '                pm.test(`test_invalidMaxLengthPathP
  │ aram Generate tempReqBody for schema: ${schemaName}`, 
  │ () => {\n' +
  │   '                    pm.expect(tempReqBody).to.not.b
  │ e.empty;\n' +
  │   '                });\n' +
  │   '            }\n' +
  │   '\n' +
  │   '            body = {\n' +
  │   "                mode: 'application/json',\n" +
  │   '                raw: JSON.stringify(tempReqBody)\n'
  │  +
  │   '            };\n' +
  │   '\n' +
  │   '            method = method.toUpperCase();\n' +
  │   '            pm.sendRequest({\n' +
  │   '                url: baseUrl + url,\n' +
  │   '                method: method,\n' +
  │   '                header: standardHeader,\n' +
  │   '                body\n' +
  │   '            }, function (err, response) {\n' +
  │   '                if (err) {\n' +
  │   '                    console.error("test_invalidMaxL
  │ engthPathParam error:", err);\n' +
  │   '                    return;\n' +
  │   '                }\n' +
  │   '                if (!response) {\n' +
  │   '                    console.warn("test_invalidMaxLe
  │ ngthPathParam undefined response for", method, url);\n
  │ ' +
  │   '                    return;\n' +
  │   '                }\n' +
  │   '\n' +
  │   '                const responseCopy = JSON.parse(JSO
  │ N.stringify(response));\n' +
  │   '                const responseCode = responseCopy.c
  │ ode;\n' +
  │   '                const responseJson = (response && r
  │ esponse.text()) ? response.json() : null;\n' +
  │   '\n' +
  │   '                let reqBody = apiSchemas[schemaName
  │ ];\n' +
  │   '\n' +
  │   "                const expectedErrors = utils.getExp
  │ ectedInvalidSchemaErrors('invalidMaxLength', null, req
  │ Body, JSON.parse(body.raw));\n" +
  │   "                const expectedTitles = lodash.map(e
  │ xpectedErrors, (obj) => lodash.omit(obj, 'type'));\n" 
  │ +
  │   "                let actualTitles = lodash.map(respo
  │ nseJson.errors, (obj) => lodash.omit(obj, 'type'));\n"
  │  +
  │   '                actualTitles = lodash.map(actualTit
  │ les, (error) => {\n' +
  │   "                    error.title = lodash.replace(er
  │ ror.title, /^\\$?\\w*(\\[\\d+\\])?(\\.\\w+(\\[\\d+\\])
  │ ?)*\\./, '');\n" +
  │   '                    return error;\n' +
  │   '                });\n' +
  │   '\n' +
  │   "                //console.log('test_maxLength'+ met
  │ hod + ' ' + url, actualTitles, expectedTitles)\n" +
  │   '\n' +
  │   "                pm.test(pm.info.requestName + ': ' 
  │ + method + ' ' + url, function () {\n" +
  │   '                    pm.expect(responseCode).to.equa
  │ l(400);\n' +
  │   '\n' +
  │   '                    // Sort expected and actual tit
  │ les alphabetically by title string\n' +
  │   "                    const sortedActualTitles = loda
  │ sh.orderBy(actualTitles, ['title'], ['asc']);\n" +
  │   "                    const sortedExpectedTitles = lo
  │ dash.orderBy(expectedTitles, ['title'], ['asc']);\n" +
  │   '\n' +
  │   '\n' +
  │   '                    // Check that all expected erro
  │ rs are present (allow additional errors)\n' +
  │   '                    const expectedTitleStrings = so
  │ rtedExpectedTitles.map(e => e.title);\n' +
  │   '                    const actualTitleStrings = sort
  │ edActualTitles.map(e => e.title);\n' +
  │   '                    \n' +
  │   '                    expectedTitleStrings.forEach(ex
  │ pectedTitle => {\n' +
  │   '                        pm.expect(actualTitleString
  │ s).to.include(expectedTitle, \n' +
  │   '                            `Expected error "${expe
  │ ctedTitle}" should be present in actual errors`);\n' +
  │   '                    });\n' +
  │   '                    \n' +
  │   '                    // Ensure we have at least the 
  │ minimum expected number of errors\n' +
  │   '                    pm.expect(actualTitleStrings.le
  │ ngth).to.be.at.least(expectedTitleStrings.length, \n' 
  │ +
  │   '                        `Should have at least ${exp
  │ ectedTitleStrings.length} validation errors`);\n' +
  │   '                });\n' +
  │   '            });\n' +
  │   '        });\n' +
  │   '    });\n' +
  │   '}'
  │ 'function test_invalidSelectQueryParam(pm, baseUrl, st
  │ andardHeader, paths) {\n' +
  │   '    const PRE_DEFINE_INT_VALUE = 1; // Default valu
  │ e for path parameters\n' +
  │   '    \n' +
  │   '    lodash.forEach(paths, (path, url) => {\n' +
  │   "        let methods = Object.keys(path).filter(key 
  │ => key !== 'parameters');\n" +
  │   '\n' +
  │   '        const basePath = url.replace(/{[^}]+}/g, PR
  │ E_DEFINE_INT_VALUE.toString());\n' +
  │   "        const invalidSelectParam = '$select=garbage
  │ ';\n" +
  │   '        let finalUrl;\n' +
  │   '\n' +
  │   '        // Special handling for currencyRates API -
  │  add required location parameter\n' +
  │   "        if (basePath.startsWith('/currencyRates')) 
  │ {\n" +
  │   '            // Check if location parameter is alrea
  │ dy present in the URL\n' +
  │   "            if (basePath.includes('location=')) {\n
  │ " +
  │   '                finalUrl = `${basePath}&${invalidSe
  │ lectParam}`;\n' +
  │   '            } else {\n' +
  │   '                finalUrl = `${basePath}?location=ge
  │ neralLedger&${invalidSelectParam}`;\n' +
  │   '            }\n' +
  │   '        } else {\n' +
  │   '            finalUrl = `${basePath}?${invalidSelect
  │ Param}`;\n' +
  │   '        }\n' +
  │   '\n' +
  │   '        lodash.forEach(methods, (method) => {\n' +
  │   "            if (method === 'delete') { return; }\n"
  │  +
  │   "            let parameters = path[method]['paramete
  │ rs'];\n" +
  │   '\n' +
  │   '            // Check if the endpoint supports $sele
  │ ct parameter\n' +
  │   "            if (!lodash.find(parameters, { '$ref': 
  │ '#/components/parameters/select' }) && \n" +
  │   "                !lodash.find(parameters, { 'name': 
  │ '$select' })) {\n" +
  │   "                console.warn('$select parameter mis
  │ sing from definition', method, url);\n" +
  │   '                return;\n' +
  │   '            }\n' +
  │   '\n' +
  │   '            let body = null;\n' +
  │   "            if (method === 'post' || method === 'pu
  │ t') {\n" +
  │   '                let tempReqBody = {};\n' +
  │   '\n' +
  │   '                // For currencyRates, provide a min
  │ imally valid body to pass initial validation\n' +
  │   "                if (basePath.startsWith('/currencyR
  │ ates')) {\n" +
  │   '                    tempReqBody = {\n' +
  │   '                        "location": "generalLedger"
  │ ,\n' +
  │   '                        "currencyCode": "CAD",\n' +
  │   '                        "exchangeRate": 1.25,\n' +
  │   '                        "effectiveDate": "2025-01-1
  │ 4"\n' +
  │   '                    };\n' +
  │   '                } else {\n' +
  │   '                    // For other APIs, use empty ob
  │ ject\n' +
  │   '                    tempReqBody = {};\n' +
  │   '                }\n' +
  │   '\n' +
  │   '                body = {\n' +
  │   "                    mode: 'application/json',\n" +
  │   '                    raw: JSON.stringify(tempReqBody
  │ )\n' +
  │   '                };\n' +
  │   '            }\n' +
  │   '\n' +
  │   '            method = method.toUpperCase();\n' +
  │   '            pm.sendRequest({\n' +
  │   '                url: baseUrl + finalUrl,\n' +
  │   '                method: method,\n' +
  │   '                body: body,\n' +
  │   '                header: standardHeader\n' +
  │   '            }, function (err, response) {\n' +
  │   '                const responseCode = (response && r
  │ esponse.code) ? response.code : null;\n' +
  │   '                const responseJson = (response && r
  │ esponse.text()) ? response.json() : {};\n' +
  │   '\n' +
  │   '                pm.test(`${pm.info.requestName}: [$
  │ {method}] ${finalUrl} - should fail for invalid $selec
  │ t`, function () {\n' +
  │   '                    if (err) {\n' +
  │   '                        pm.expect.fail(`Request fai
  │ led with an error: ${err}`);\n' +
  │   '                        return;\n' +
  │   '                    }\n' +
  │   '                    \n' +
  │   "                    // Expect 400 Bad Request due t
  │ o invalid '$select' parameter\n" +
  │   `                    pm.expect(responseCode, "Expect
  │ ed a 400 Bad Request due to invalid '$select' paramete
  │ r").to.equal(400);\n` +
  │   '\n' +
  │   '                    // Check for the specific error
  │  message about $select parameter\n' +
  │   '                    if (responseJson.errors && resp
  │ onseJson.errors.length > 0) {\n' +
  │   '                        const errorTitle = response
  │ Json.errors[0].title || "";\n' +
  │   `                        pm.expect(errorTitle, "Erro
  │ r message should mention the $select parameter").to.co
  │ ntain('$select query parameter');\n` +
  │   '                    } else if (responseJson.error) 
  │ {\n' +
  │   '                        // Some APIs might return e
  │ rror in different format\n' +
  │   '                        const errorMessage = respon
  │ seJson.error.message || responseJson.error.title || ""
  │ ;\n' +
  │   `                        pm.expect(errorMessage, "Er
  │ ror message should mention the $select parameter").to.
  │ contain('$select');\n` +
  │   '                    } else {\n' +
  │   '                        console.warn(`No error mess
  │ age found in response for ${method} ${finalUrl}`);\n' 
  │ +
  │   '                    }\n' +
  │   '                });\n' +
  │   '            });\n' +
  │   '        });\n' +
  │   '    });\n' +
  │   '}'
  │ 'function test_invalidSortByQueryParam(pm, baseUrl, st
  │ andardHeader, paths) {\n' +
  │   '    const PRE_DEFINE_INT_VALUE = 1; // Default valu
  │ e for path parameters\n' +
  │   "    const ORDER_BY_PARAM = '$orderBy'; // The param
  │ eter we're testing\n" +
  │   '    \n' +
  │   '    lodash.forEach(paths, (path, url) => {\n' +
  │   "        let methods = Object.keys(path).filter(key 
  │ => key !== 'parameters');\n" +
  │   '\n' +
  │   '        const basePath = url.replace(/{[^}]+}/g, PR
  │ E_DEFINE_INT_VALUE.toString());\n' +
  │   '        const invalidOrderByParam = `${ORDER_BY_PAR
  │ AM}=garbage`;\n' +
  │   '        let finalUrl;\n' +
  │   '\n' +
  │   '        // Special handling for currencyRates API -
  │  add required location parameter\n' +
  │   "        if (basePath.startsWith('/currencyRates')) 
  │ {\n" +
  │   '            // Check if location parameter is alrea
  │ dy present in the URL\n' +
  │   "            if (basePath.includes('location=')) {\n
  │ " +
  │   '                finalUrl = `${basePath}&${invalidOr
  │ derByParam}`;\n' +
  │   '            } else {\n' +
  │   '                finalUrl = `${basePath}?location=ge
  │ neralLedger&${invalidOrderByParam}`;\n' +
  │   '            }\n' +
  │   '        } else {\n' +
  │   '            finalUrl = `${basePath}?${invalidOrderB
  │ yParam}`;\n' +
  │   '        }\n' +
  │   '\n' +
  │   '        lodash.forEach(methods, (method) => {\n' +
  │   "            if (method === 'delete') { return; }\n"
  │  +
  │   "            let parameters = path[method]['paramete
  │ rs'];\n" +
  │   '\n' +
  │   '            // Check if the endpoint supports $orde
  │ rBy parameter\n' +
  │   "            if (!lodash.find(parameters, { '$ref': 
  │ '#/components/parameters/orderBy' }) && \n" +
  │   "                !lodash.find(parameters, { 'name': 
  │ '$orderBy' })) {\n" +
  │   "                console.warn('$orderBy parameter mi
  │ ssing from definition', method, url);\n" +
  │   '                return;\n' +
  │   '            }\n' +
  │   '\n' +
  │   '            let body = null;\n' +
  │   "            if (method === 'post' || method === 'pu
  │ t') {\n" +
  │   '                let tempReqBody = {};\n' +
  │   '\n' +
  │   '                // For currencyRates, provide a min
  │ imally valid body to pass initial validation\n' +
  │   "                if (basePath.startsWith('/currencyR
  │ ates')) {\n" +
  │   '                    tempReqBody = {\n' +
  │   '                        "location": "generalLedger"
  │ ,\n' +
  │   '                        "currencyCode": "CAD",\n' +
  │   '                        "exchangeRate": 1.25,\n' +
  │   '                        "effectiveDate": "2025-01-1
  │ 4"\n' +
  │   '                    };\n' +
  │   '                } else {\n' +
  │   '                    // For other APIs, use empty ob
  │ ject\n' +
  │   '                    tempReqBody = {};\n' +
  │   '                }\n' +
  │   '\n' +
  │   '                body = {\n' +
  │   "                    mode: 'application/json',\n" +
  │   '                    raw: JSON.stringify(tempReqBody
  │ )\n' +
  │   '                };\n' +
  │   '            }\n' +
  │   '\n' +
  │   '            method = method.toUpperCase();\n' +
  │   '            pm.sendRequest({\n' +
  │   '                url: baseUrl + finalUrl,\n' +
  │   '                method: method,\n' +
  │   '                body: body,\n' +
  │   '                header: standardHeader\n' +
  │   '            }, function (err, response) {\n' +
  │   '                const responseCode = (response && r
  │ esponse.code) ? response.code : null;\n' +
  │   '                const responseJson = (response && r
  │ esponse.text()) ? response.json() : {};\n' +
  │   '\n' +
  │   '                pm.test(`${pm.info.requestName}: [$
  │ {method}] ${finalUrl} - should fail for invalid $order
  │ By`, function () {\n' +
  │   '                    if (err) {\n' +
  │   '                        pm.expect.fail(`Request fai
  │ led with an error: ${err}`);\n' +
  │   '                        return;\n' +
  │   '                    }\n' +
  │   '                    \n' +
  │   "                    // Expect 400 Bad Request due t
  │ o invalid '$orderBy' parameter\n" +
  │   `                    pm.expect(responseCode, "Expect
  │ ed a 400 Bad Request due to invalid '$orderBy' paramet
  │ er").to.equal(400);\n` +
  │   '\n' +
  │   '                    // Check for the specific error
  │  message about $orderBy parameter\n' +
  │   '                    if (responseJson.errors && resp
  │ onseJson.errors.length > 0) {\n' +
  │   '                        const errorTitle = response
  │ Json.errors[0].title || "";\n' +
  │   `                        pm.expect(errorTitle, "Erro
  │ r message should mention the $orderBy parameter").to.c
  │ ontain('$orderBy query parameter');\n` +
  │   '                    } else if (responseJson.error) 
  │ {\n' +
  │   '                        // Some APIs might return e
  │ rror in different format\n' +
  │   '                        const errorMessage = respon
  │ seJson.error.message || responseJson.error.title || ""
  │ ;\n' +
  │   `                        pm.expect(errorMessage, "Er
  │ ror message should mention the $orderBy parameter").to
  │ .contain('$orderBy');\n` +
  │   '                    } else {\n' +
  │   '                        console.warn(`No error mess
  │ age found in response for ${method} ${finalUrl}`);\n' 
  │ +
  │   '                    }\n' +
  │   '                });\n' +
  │   '            });\n' +
  │   '        });\n' +
  │   '    });\n' +
  │   '}'
  │ 'function test_invalidFilterQueryParam(pm, baseUrl, st
  │ andardHeader, paths) {\n' +
  │   '\n' +
  │   '    function sendInvalidFilter(requestPath) {\n' +
  │   '        pm.sendRequest({\n' +
  │   '            url: baseUrl + requestPath, // requestP
  │ ath now includes the query string\n' +
  │   "            method: 'GET',\n" +
  │   '            header: standardHeader\n' +
  │   '        }, function (err, response) {\n' +
  │   '            if (err) {\n' +
  │   '                console.error(pm.info.requestName +
  │  " error:", err);\n' +
  │   '                return;\n' +
  │   '            }\n' +
  │   '            if (!response) {\n' +
  │   '                console.warn(pm.info.requestName + 
  │ " undefined response for:", requestPath);\n' +
  │   '                return;\n' +
  │   '            }\n' +
  │   '\n' +
  │   '            const responseCopy = JSON.parse(JSON.st
  │ ringify(response));\n' +
  │   '            const responseCode = responseCopy.code;
  │ \n' +
  │   '            const responseJson = (response && respo
  │ nse.text()) ? response.json() : null;\n' +
  │   '            const errorTitle = responseJson.errors?
  │ .[0]?.title || "";\n' +
  │   "            pm.test(pm.info.requestName + ': GET ' 
  │ + requestPath, function () {\n" +
  │   "                pm.expect(responseCode, 'Should ret
  │ urn a 400 Bad Request').to.equal(400);\n" +
  │   "                pm.expect(errorTitle, 'Error messag
  │ e should mention the filter parameter').to.contain('$f
  │ ilter query parameter');\n" +
  │   '            });\n' +
  │   '        });\n' +
  │   '    }\n' +
  │   '\n' +
  │   '    function getSampleProperty(schemaName, url) {\n
  │ ' +
  │   "        let schema = pm.globals.get('apiSchemas')[s
  │ chemaName].properties;\n" +
  │   "        const parts = url.split('/');\n" +
  │   '        const prop = parts[parts.length - 1];\n' +
  │   "        schema = lodash.get(schema, [prop, 'items',
  │  'properties'], {});\n" +
  │   '        let sampleProp = lodash.sample(Object.keys(
  │ schema));\n' +
  │   '        return sampleProp;\n' +
  │   '    }\n' +
  │   '\n' +
  │   '    lodash.forEach(paths, (path, url) => {\n' +
  │   "        let methods = Object.keys(path).filter(key 
  │ => key !== 'parameters');\n" +
  │   "        if (lodash.indexOf(methods, 'get') < 0) { r
  │ eturn; }\n" +
  │   '        \n' +
  │   "        let parameters = path['get']['parameters'];
  │ \n" +
  │   "        if (!lodash.find(parameters, { '$ref': '#/c
  │ omponents/parameters/filter' }) && !lodash.find(parame
  │ ters, { 'name': '$filter' })) {\n" +
  │   "            console.warn('$filter parameter missing
  │  from definition', url);\n" +
  │   '            return;\n' +
  │   '        }\n' +
  │   '\n' +
  │   '        const modifiedUrl = url.replace(/{[^}]+}/g,
  │  PRE_DEFINE_INT_VALUE.toString());\n' +
  │   '\n' +
  │   '        // --- NEW LOGIC INTEGRATED HERE --- //\n' 
  │ +
  │   '\n' +
  │   '        /**\n' +
  │   '         * Builds the final test URL.\n' +
  │   "         * Applies special handling for /currencyRa
  │ tes by adding a required 'location' parameter.\n" +
  │   '         * @param {string} basePath - The base endp
  │ oint path (e.g., /currencyRates).\n' +
  │   '         * @param {string} invalidFilterParam - The
  │  invalid filter parameter string (e.g., $filter=garbag
  │ e eq abc).\n' +
  │   '         * @returns {string} The fully constructed 
  │ URL path with query parameters.\n' +
  │   '         */\n' +
  │   '        const buildTestUrl = (basePath, invalidFilt
  │ erParam) => {\n' +
  │   "            if (basePath.startsWith('/currencyRates
  │ ')) {\n" +
  │   "                // For /currencyRates, add the requ
  │ ired 'location' parameter first\n" +
  │   '                return `${basePath}?location=genera
  │ lLedger&${invalidFilterParam}`;\n' +
  │   '            } else {\n' +
  │   '                // For all other paths, just add th
  │ e invalid filter parameter\n' +
  │   '                return `${basePath}?${invalidFilter
  │ Param}`;\n' +
  │   '            }\n' +
  │   '        };\n' +
  │   '        \n' +
  │   '        // Test Case 1: A completely invalid filter
  │  value\n' +
  │   "        const invalidFilter1 = '$filter=garbage eq 
  │ abc';\n" +
  │   '        sendInvalidFilter(buildTestUrl(modifiedUrl,
  │  invalidFilter1));\n' +
  │   '\n' +
  │   '        // Test Case 2: A valid property with a mis
  │ sing value\n' +
  │   `        let schemaName = path['get'].responses['200
  │ '].content["application/json"].schema['$ref'].replace(
  │ '#/components/schemas/', '');\n` +
  │   '        let sampleProp = getSampleProperty(schemaNa
  │ me, url);\n' +
  │   '        \n' +
  │   '        if (sampleProp) {\n' +
  │   '            const invalidFilter2 = `$filter=${sampl
  │ eProp} eq`;\n' +
  │   '            sendInvalidFilter(buildTestUrl(modified
  │ Url, invalidFilter2));\n' +
  │   '        }\n' +
  │   '    });\n' +
  │   '}'
  │ 'function test_requiredCannotBeNullable(pm, openApiSch
  │ ema) {\n' +
  │   '    //console.log("openApiSchema", openApiSchema);\
  │ n' +
  │   '    lodash.forEach(openApiSchema, (model, modelName
  │ ) => {\n' +
  │   '        //console.log(modelName, model);\n' +
  │   "        if (lodash.has(model, 'required') && lodash
  │ .isArray(model.required)) {\n" +
  │   '            lodash.forEach(model.required, (require
  │ dField) => {\n' +
  │   '                const property = lodash.get(model, 
  │ `properties.${requiredField}`);\n' +
  │   "                pm.test(`${modelName}: Field '${req
  │ uiredField}' should not be nullable`, function () {\n"
  │  +
  │   '                    //pm.expect(property.nullable).
  │ to.be.false;\n' +
  │   "                    pm.expect(property).to.not.have
  │ .property('nullable');\n" +
  │   '                });\n' +
  │   '            });\n' +
  │   '        }\n' +
  │   '    });\n' +
  │   '}'
  │ 'function test_whiteSpaceInPath(pm, paths) {\n' +
  │   '    //console.log("openApiSchema", openApiSchema);\
  │ n' +
  │   '    lodash.forEach(paths, (path, url) => {\n' +
  │   "        if (lodash.includes(['/version', '/whoami',
  │  '/login'], url)) { return; }\n" +
  │   "        if (url.includes('{')) { return; }\n" +
  │   '\n' +
  │   "        //if(!url.startsWith('/eligibleCarriers')){
  │  return; }\n" +
  │   '\n' +
  │   "        let methods = Object.keys(path).filter(key 
  │ => key !== 'parameters');\n" +
  │   "        if (lodash.indexOf(methods, 'get') < 0) { r
  │ eturn; }\n" +
  │   '\n' +
  │   '        let requiredParameters = lodash.filter(path
  │ .get.parameters, function (el, i) { return el.required
  │  == true; });\n' +
  │   '        if (requiredParameters.length > 0) { return
  │ ; }\n' +
  │   '\n' +
  │   '        pm.sendRequest(\n' +
  │   '            {\n' +
  │   '                url: pm.environment.get("baseUrl") 
  │ + url + "/   ",\n' +
  │   "                method: 'GET',\n" +
  │   '                header: standardHeader\n' +
  │   '            },\n' +
  │   '            function (err, response) {\n' +
  │   '                let responseCode = response.code;\n
  │ ' +
  │   '                let responseJson = (response.text()
  │ ) ? response.json() : {};\n' +
  │   "                pm.test('GET ' + url, function () {
  │ \n" +
  │   '                    pm.expect(responseCode).to.equa
  │ l(200);\n' +
  │   '                });\n' +
  │   '            }\n' +
  │   '        );\n' +
  │   '    });\n' +
  │   '}'
  │ 'function test_schemaValidation(pm, paths) {\n' +
  │   '\n' +
  │   '    lodash.forEach(paths, (path, url) => {\n' +
  │   "        if (url.includes('/status')) { return; }\n"
  │  +
  │   "        if (url.includes('{')) { return; }\n" +
  │   '\n' +
  │   "        //if(!url.startsWith('/eligibleCarriers')){
  │  return; }\n" +
  │   '\n' +
  │   "        let methods = Object.keys(path).filter(key 
  │ => key !== 'parameters');\n" +
  │   "        if (lodash.indexOf(methods, 'get') < 0) { r
  │ eturn; }\n" +
  │   '        let requiredParameters = lodash.filter(path
  │ .get.parameters, function (el, i) { return el.required
  │  == true; });\n' +
  │   '        if (requiredParameters.length > 0) { return
  │ ; }\n' +
  │   '\n' +
  │   '        pm.sendRequest(\n' +
  │   '            {\n' +
  │   '                url: pm.environment.get("baseUrl") 
  │ + url,\n' +
  │   "                method: 'GET',\n" +
  │   '                header: standardHeader\n' +
  │   '            },\n' +
  │   '            function (err, response) {\n' +
  │   '                if (err || response.code != 200) {\
  │ n' +
  │   "                    //console.error('Response:' + r
  │ esponse.text(), response);\n" +
  │   "                    pm.test(pm.info.requestName + '
  │ : GET ' + url, function () {\n" +
  │   '                        pm.expect(response.code).to
  │ .equal(200);\n' +
  │   '                    });\n' +
  │   '                    return;\n' +
  │   '                }\n' +
  │   '\n' +
  │   '                let responseCode = response.code;\n
  │ ' +
  │   '                let responseJson = (response.text()
  │ ) ? response.json() : {};\n' +
  │   '\n' +
  │   "                pm.test('GET ' + url, function () {
  │ \n" +
  │   '                    pm.expect(responseCode).to.equa
  │ l(200);\n' +
  │   '                });\n' +
  │   '\n' +
  │   `                let schemaName = path['get'].respon
  │ ses['200'].content["application/json"].schema['$ref'].
  │ replace('#/components/schemas/', '');\n` +
  │   '                utils.validateJsonSchema(schemaName
  │ , responseJson);\n' +
  │   '\n' +
  │   '            }\n' +
  │   '        );\n' +
  │   '    });\n' +
  │   '}'
  │ "function buildPathDefinitions({paths, queryString = '
  │ ', allowedMethods = ['get', 'post', 'put']}){\n" +
  │   '    return lodash.transform(paths, (result, path, u
  │ rl) => {\n' +
  │   '        if (!filters.urlFilter(url)) return;\n' +
  │   '\n' +
  │   '        const availableMethods = allowedMethods.fil
  │ ter(method => path[method]);\n' +
  │   '        if (!availableMethods.length) return;\n' +
  │   "        //console.log('availableMethods', available
  │ Methods);\n" +
  │   '\n' +
  │   '        // Normalize URL by replacing path params a
  │ nd appending query string\n' +
  │   "        //const normalizedUrl = url.replace(/{[^}]+
  │ }/g, '0') + queryString;\n" +
  │   '\n' +
  │   '        const normalizedUrl = url.replace(/{[^}]+}/
  │ g, PRE_DEFINE_INT_VALUE.toString()) + queryString;\n' 
  │ +
  │   '        \n' +
  │   '\n' +
  │   '        const methods = {};\n' +
  │   '        availableMethods.forEach(method => {\n' +
  │   '            //if (path[method]) {\n' +
  │   '                methods[method] = {};\n' +
  │   '                const requestBody = path[method].re
  │ questBody;\n' +
  │   "                if (requestBody?.content?.['applica
  │ tion/json']?.schema?.['$ref']) {\n" +
  │   "                    const schemaRef = requestBody.c
  │ ontent['application/json'].schema['$ref'];\n" +
  │   "                    const schemaName = schemaRef.re
  │ place('#/components/schemas/', '');\n" +
  │   '                    methods[method].requestBodySche
  │ maName = schemaName;\n' +
  │   '                    methods[method].requestBody = u
  │ tils.getExampleRequestBody({ schemaName, maxItems: 1 }
  │ );\n' +
  │   '                }\n' +
  │   '            //}\n' +
  │   '        });\n' +
  │   '        result[normalizedUrl] = methods;\n' +
  │   '        \n' +
  │   '    }, {});\n' +
  │   '}'
  │ 'function responseValidation({ pm, baseUrl, header, pa
  │ ths, expectedMessage, delayFn }) {\n' +
  │   '    // Run single request & test\n' +
  │   '    function runTest(method, url, properties) {\n' 
  │ +
  │   "        //console.log('runTest: '+method, url, expe
  │ ctedMessage);\n" +
  │   '\n' +
  │   '        body = null;\n' +
  │   '        if(properties.requestBody){\n' +
  │   '            body = {\n' +
  │   "                    mode: 'application/json',\n" +
  │   '                    raw: JSON.stringify(properties.
  │ requestBody)\n' +
  │   '                };\n' +
  │   '        }\n' +
  │   '\n' +
  │   '        if(!pm){\n' +
  │   "            console.error('responseValidation pm is
  │  undefined');\n" +
  │   '        }\n' +
  │   '\n' +
  │   '        return new Promise(resolve => {\n' +
  │   '            pm.sendRequest({\n' +
  │   '                url: baseUrl+url,\n' +
  │   '                method: method,\n' +
  │   '                header: standardHeader,\n' +
  │   '                body: body\n' +
  │   '            }, function (err, response) {\n' +
  │   '                if (err) {\n' +
  │   '                    console.error(url, err);\n' +
  │   '                }\n' +
  │   '                const responseJson = (response && r
  │ esponse.text()) ? response.json() : null;\n' +
  │   '                const responseCode = (response && r
  │ esponse.code) ? response.code : null;\n' +
  │   '                \n' +
  │   '                // --- INSERT CASE-INSENSITIVE FIX 
  │ HERE ---\n' +
  │   "                const expectedMessageFound = lodash
  │ .some(lodash.get(responseJson, 'errors', []),\n" +
  │   '                    (err) => {\n' +
  │   "                        // 1. Get the server's erro
  │ r title and convert it to lowercase\n" +
  │   "                        const errorTitle = lodash.g
  │ et(err, 'title', '').toLowerCase(); \n" +
  │   '                        \n' +
  │   '                        // 2. Convert the expected 
  │ message to lowercase for a consistent comparison\n' +
  │   '                        const expected = expectedMe
  │ ssage.toLowerCase();                 \n' +
  │   '                        \n' +
  │   '                        // 3. Perform the case-inse
  │ nsitive check using lodash.includes\n' +
  │   '                        return lodash.includes(erro
  │ rTitle, expected);\n' +
  │   '                    }\n' +
  │   '                );\n' +
  │   '                // --- END CASE-INSENSITIVE FIX ---
  │ \n' +
  │   '\n' +
  │   '\n' +
  │   "               // const expectedMessageFound = loda
  │ sh.some(lodash.get(responseJson, 'errors', []),\n" +
  │   "               //     (err) => lodash.includes(loda
  │ sh.get(err, 'title', ''), expectedMessage)\n" +
  │   '               // );\n' +
  │   '                const errorsLength = responseJson?.
  │ errors?.length ?? 0;\n' +
  │   '\n' +
  │   '                pm.test(`400 response validation ${
  │ method} ${url}`, function () {\n' +
  │   '                    pm.expect(responseCode).to.equa
  │ l(400);\n' +
  │   '                    pm.expect(expectedMessageFound)
  │ .to.be.true;\n' +
  │   '                    if(properties.errorsCount){\n' 
  │ +
  │   "                        //console.log(errorsLength+
  │ ' = errorsCount:',properties.errorsCount);\n" +
  │   '                        pm.expect(errorsLength).to.
  │ equal(properties.errorsCount);\n' +
  │   '                    }\n' +
  │   '                });\n' +
  │   '\n' +
  │   '                resolve();\n' +
  │   '            });\n' +
  │   '        });\n' +
  │   '    }\n' +
  │   '\n' +
  │   '    console.info(`---------- ${pm.execution.locatio
  │ n.slice(1).join(" > ")} - Begin Validation ----------`
  │  );\n' +
  │   '\n' +
  │   '    // Chain sequential promises\n' +
  │   '    let chain = Promise.resolve();\n' +
  │   '    if(!paths){\n' +
  │   "        console.error('responseValidation paths is 
  │ undefined');\n" +
  │   '    }\n' +
  │   '    lodash.forEach(paths, (methods, url) => {\n' +
  │   '        lodash.forEach(methods, (properties, method
  │ ) => {\n' +
  │   '            chain = chain\n' +
  │   '                //.then(() => runTest(method, url, 
  │ properties.requestBody))\n' +
  │   '                .then(() => runTest(method, url, pr
  │ operties))\n' +
  │   '                .then(() => delayFn()); // use call
  │ er-provided delay\n' +
  │   '        });\n' +
  │   '    });\n' +
  │   '\n' +
  │   '    return chain.then(() => {\n' +
  │   '        //console.log("responseValidation completed
  │ ");\n' +
  │   '        console.info(`---------- ${pm.execution.loc
  │ ation.slice(1).join(" > ")} - Validation Completed ---
  │ -------` );\n' +
  │   '    });\n' +
  │   '}'
  │ '[object Object]'
  └

[90m┌─────────────────────────[39m[90m┬──────────[39m[90m┬──────────┐[39m
[90m│[39m                         [90m│[39m executed [90m│[39m   failed [90m│[39m
[90m├─────────────────────────[39m[90m┼──────────[39m[90m┼──────────┤[39m
[90m│[39m              iterations [90m│[39m        1 [90m│[39m        0 [90m│[39m
[90m├─────────────────────────[39m[90m┼──────────[39m[90m┼──────────┤[39m
[90m│[39m                requests [90m│[39m        0 [90m│[39m        0 [90m│[39m
[90m├─────────────────────────[39m[90m┼──────────[39m[90m┼──────────┤[39m
[90m│[39m            test-scripts [90m│[39m        0 [90m│[39m        0 [90m│[39m
[90m├─────────────────────────[39m[90m┼──────────[39m[90m┼──────────┤[39m
[90m│[39m      prerequest-scripts [90m│[39m        1 [90m│[39m        0 [90m│[39m
[90m├─────────────────────────[39m[90m┼──────────[39m[90m┼──────────┤[39m
[90m│[39m              assertions [90m│[39m        0 [90m│[39m        0 [90m│[39m
[90m├─────────────────────────┴──────────┴──────────┤[39m
[90m│[39m total run duration: 767 ms                    [90m│[39m
[90m├───────────────────────────────────────────────┤[39m
[90m│[39m total data received: 0 B (approx)             [90m│[39m
[90m└───────────────────────────────────────────────┘[39m

Uploading Postman CLI run data to Postman Cloud...
Uploaded successfully! View on Postman: https://go.postman.co/workspace/2fe98945-c29d-438d-8ad7-328f4624b017/run/2332132-e6ac7167-b799-4257-ad68-d96781f0709e


A new version of Postman CLI is available (v1.22.0). Refer https://go.pstmn.io/cli-release-notes for changelogs.
To update your Postman CLI, follow the steps at https://go.pstmn.io/update-cli
