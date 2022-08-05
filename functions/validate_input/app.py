"""
    Validate input to the workload state machine
"""
import logging
from os import environ

from aws_xray_sdk.core import patch_all, xray_recorder

from stax_orchestrator import StaxOrchestrator

logging.getLogger().setLevel(environ.get("LOG_LEVEL", logging.INFO))

xray_recorder.configure(service="StaxOrchestrator:ValidateInput")
patch_all()


def lambda_handler(event: dict, _) -> dict:
    """Validate input to workload state machine

    Args:
        event (dict): Details about the workload to be deployed/updated/deleted

    Returns:
        WorkloadEvent: Details about the catalogue, workload and account

    Raises:
        KeyError: Raised when required event arguments are not present
    """
    stax_orchestrator = StaxOrchestrator()
    try:
        if event["operation"] == stax_orchestrator.WorkloadOperation.DEPLOY:
            workload_kwargs = stax_orchestrator.get_deploy_workload_kwargs(event)
            return stax_orchestrator.CreateWorkloadEvent(**workload_kwargs).__dict__

        if event["operation"] == stax_orchestrator.WorkloadOperation.UPDATE:
            workload_kwargs = stax_orchestrator.get_update_workload_kwargs(event)
            return stax_orchestrator.UpdateWorkloadEvent(**workload_kwargs).__dict__

        if event["operation"] == stax_orchestrator.WorkloadOperation.DELETE:
            workload_kwargs = stax_orchestrator.get_delete_workload_kwargs(event)
            return stax_orchestrator.DeleteWorkloadEvent(**workload_kwargs).__dict__

        raise stax_orchestrator.WorkloadOperationNotSupported(
            f"{event['operation']} is not a supported operation."
        )

    except KeyError as missing_key:
        raise stax_orchestrator.MissingRequiredInput(
            f"Missing required input key: {missing_key} from the event payload."
        ) from missing_key