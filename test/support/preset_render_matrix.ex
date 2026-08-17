defmodule Rendro.TestSupport.PresetRenderMatrix do
  @moduledoc false

  @rows [
    {:swiss_invoice_light, :swiss, :light, :invoice},
    {:swiss_certificate_dark, :swiss, :dark, :certificate},
    {:humanist_receipt_light, :humanist, :light, :receipt},
    {:humanist_payslip_dark, :humanist, :dark, :payslip},
    {:editorial_certificate_light, :editorial, :light, :certificate},
    {:editorial_ticket_dark, :editorial, :dark, :ticket},
    {:corporate_classic_branded_invoice_light, :corporate_classic, :light, :branded_invoice},
    {:corporate_classic_invoice_dark, :corporate_classic, :dark, :invoice},
    {:minimal_mono_statement_light, :minimal_mono, :light, :statement},
    {:minimal_mono_ticket_dark, :minimal_mono, :dark, :ticket},
    {:brutalist_receipt_light, :brutalist, :light, :receipt},
    {:brutalist_payslip_dark, :brutalist, :dark, :payslip}
  ]

  @spec rows() :: [{atom(), atom(), atom(), atom()}]
  def rows, do: @rows
end
