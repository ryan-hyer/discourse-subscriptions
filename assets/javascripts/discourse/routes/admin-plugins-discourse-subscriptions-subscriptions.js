import I18n from "I18n";
import Route from "@ember/routing/route";
import AdminSubscription from "discourse/plugins/discourse-subscriptions/discourse/models/admin-subscription";
import { action } from "@ember/object";
import bootbox from "bootbox";

export default Route.extend({
  model() {
    return AdminSubscription.find();
  },

  @action
  cancelSubscription(model) {
    const subscription = model.subscription;
    const refund = model.refund;
    subscription.set("loading", true);
    subscription
      .destroy(refund)
      .then((result) => {
        subscription.set("status", result.status);
        this.send("closeModal");
        bootbox.alert(I18n.t("discourse_subscriptions.admin.canceled"));
      })
      .catch((data) => bootbox.alert(data.jqXHR.responseJSON.errors.join("\n")))
      .finally(() => {
        subscription.set("loading", false);
        this.refresh();
      });
  },
});
