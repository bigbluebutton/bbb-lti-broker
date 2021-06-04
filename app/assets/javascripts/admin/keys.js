function redirectConfig(xml_config_path, placeholder) {
    const app = document.getElementById('lti_app_name').value;
    window.location.href = xml_config_path.replace(placeholder,app)
}
