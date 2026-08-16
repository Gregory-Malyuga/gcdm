local ADDON_NAME, ns = ...

function ns.Tests.Behavior.Viewers(h, ctx)
	local registry = ctx.registry
	h.check("EssentialCooldownViewer exists", registry and registry:Essential() ~= nil)
	h.check("UtilityCooldownViewer exists", registry and registry:Utility() ~= nil)
	h.check("BuffIconCooldownViewer exists", registry and registry:Buff() ~= nil)
	h.check("BuffBarCooldownViewer exists", registry and registry:BuffBar() ~= nil)
end
