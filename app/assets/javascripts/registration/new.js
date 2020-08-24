function updateAppURL(random_key, json_config, open_id_launch, deep_link_request_launch, open_id_login){
    let app = document.getElementById('lti_app_name').value;
    let jsonConfig = document.getElementById('jsonconfigurl');
    let jsonConfigLink = document.getElementById('jsonconfiglink');
    let openIDLaunch = document.getElementById('toolurl');
    let deepLinkRequestLaunch = document.getElementById('deeplinkurl');
    let initLogin = document.getElementById('initloginurl');
    let redirect = document.getElementById('redirurl');

    jsonConfig.value = changeApp(json_config, random_key, app);
    jsonConfigLink.href = jsonConfig.value;
    openIDLaunch.value = changeApp(open_id_launch, random_key, app);
    deepLinkRequestLaunch.value = changeApp(deep_link_request_launch, random_key, app);
    initLogin.value = changeApp(open_id_login, random_key, app);
    redirect.value = openIDLaunch.value + '\n' + deepLinkRequestLaunch.value
}

function changeApp(url, originalApp, newApp) {
    return url.replace(originalApp, newApp);
}
