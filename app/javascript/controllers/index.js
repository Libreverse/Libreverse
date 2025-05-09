// This file is auto-generated by ./bin/rails stimulus:manifest:update
// Run that command whenever you add a new controller or create them with
// ./bin/rails generate stimulus controllerName

import { application } from "./application";

import ApplicationController from "./application_controller";
application.register("application", ApplicationController);

import DismissibleController from "./dismissible_controller";
application.register("dismissible", DismissibleController);

import DrawerController from "./drawer_controller";
application.register("drawer", DrawerController);

import FormAutoSubmitController from "./form_auto_submit_controller";
application.register("form-auto-submit", FormAutoSubmitController);

import LenisController from "./lenis_controller";
application.register("lenis", LenisController);

import LinkController from "./link_controller";
application.register("link", LinkController);

import NavigationShortcutsController from "./navigation_shortcuts_controller";
application.register("navigation-shortcuts", NavigationShortcutsController);

import RaindropController from "./raindrop_controller";
application.register("raindrop", RaindropController);

import SearchUrlUpdaterController from "./search_url_updater_controller";
application.register("search-url-updater", SearchUrlUpdaterController);

import SidebarController from "./sidebar_controller";
application.register("sidebar", SidebarController);

import ToastController from "./toast_controller";
application.register("toast", ToastController);

import ConsentController from "./consent_controller";
application.register("consent", ConsentController);
